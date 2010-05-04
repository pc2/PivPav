#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

# TODO: add $config from command line

set PATH_LEVEL "../.."

# ===================================================================== #
# Configure patterns and variables
# Patterns will be matched in sequential manner. One after the another.
# Therefor they have to appear in proper order.
# If pattern found, result will be stored to variable.
# ===================================================================== #
#     pattern       |                       variable

#set config [list \
#]
#set conf_num 0


# ===================================================================== #
# return "" if this is script is not linked
# return "linked fname" otherwise
proc is_linked {fname} {
  set rc [ catch {set link [ file link $fname ]} ]
  if {$rc == 0} {
    return $link
  }
  return ""
}

proc get_homedir {} {
  upvar #0 argv0 script_name

  # when linked
  set fname [ is_linked $script_name ] 
  if { [ string compare $fname "" ] != 0 } {
    set script_name $fname
  }
  # find homedir of the script
  set HOMEDIR [ file dirname $script_name ]
  return $HOMEDIR
}

# ===================================================================== #
proc parse_args {argv} {
  set rep_file ""
  set ::m_id_flag 0
  set ::m_id_val  ""

  set size [ llength $argv ]
  for {set i 0} {$i < $size} {incr i 1} {
    set flag [lindex $argv $i ]
    set val  [lindex $argv [ expr $i+1 ] ]
    # puts "#size=$size #i=$i #flag = $flag  #val=$val "

    switch -- $flag {
      "-m_id" {
        set ::m_id_flag 1
        set ::m_id_val $val
        incr i 1
      }
      "-e" {
        set ::ext_pat [ lindex $argv $i ]
        incr i 1
      }
      "-p" {
        set ::process_name [ lindex $argv $i ]
        incr i 1
      }
      "-s" {
        set ::SQL_FLAG 1
#        set ::ROWID $val
#        incr i 1
      }
      default {
        # check if file extension is provided
        if { [info exists ::ext_pat] == 0 || [info exists ::process_name] == 0 } {
          puts stderr "You have to specify log filename"
          exit 1
        }

        set fname $flag
        if {[ file isfile $fname ] == 0 } {
          puts stderr "File: '$fname' does not exists"
          exit 1
        }
        set ext [ string tolower [ file extension $fname]]
        if {[string compare $ext $::ext_pat] == 0} {
          set rep_file $fname
        } else {
          puts stderr "File: '$fname' not recognized as $::process_name report";
          puts stderr "It's expected that file will have '$::ext_pat' extension"
          exit
        }
      }
    }
  }

  if {$::SQL_FLAG == 1 } {
#    if {[string compare $::ROWID "" ] == 0 } {
#      puts stderr  "ROWID not specified"
#      exit
#    } elseif {![ regexp {^\d+$} $::ROWID ] } {
#      puts stderr  "ROWID is not an number: '$::ROWID'"
#      exit
#    }
  }

  if {[string compare $rep_file "" ] == 0 } {
    puts stderr "Missing filename!"
    exit
  }

#  puts "ext_pat = $::ext_pat"
#  puts "pr_name = $::process_name"
#  puts "sql_fla = $::SQL_FLAG"
#  puts "rep_fil = $rep_file"
#  exit
  return $rep_file
}


# ===================================================================== #
# Applies pattern from $config to $line of the logfile.
# When matches result is stored to variable
# Returns 1 when successfully matched otherwise 0.
# ===================================================================== #
proc test {line conf_num} {
  set l [ get_patval $conf_num]
  set pat [lindex $l 0 ]
  set var [lindex $l 1 ]

  set lmatched [ regexp -nocase -inline -- $pat $line ]
  set lm_size [ llength $lmatched ]
  #  if not found return
  if {$lm_size == 0 } { return 0 }

  # assign subpatterns to vars
  set varlist [ regexp -all -inline {\S+} $var ]
  for {set i 0; set j 1 } {$j < $lm_size } {incr i; incr j} {
    set varname [ lindex $varlist $i ]
    global $varname
    set val [ lindex $lmatched $j ]
    # wrap value around " " when it's not an number
    if {![regexp {^n|^t} $varname]} {
      set val \"$val\"
    }
    set $varname $val
  }
  return 1 
}

# ===================================================================== #
# parse logdata
# returns (number of pattern which failed), (line number where last pattern matched)
# ===================================================================== #
proc parse {logdata start_line_num conf_num conf_size} {
#  puts [ format "parse:   line_num = %3d  conf_num = %3d  conf_size = %d" \
    "$start_line_num" "$conf_num" "$conf_size" ]

  set line_num 0
  set last_matched_line_num 0
  foreach line [ split $logdata "\n" ] {
    incr line_num 1
    # seek proper line in file
    if {$line_num < $start_line_num} { continue }

    # try to match
    if {[ test $line $conf_num ] == 1 } {
        set last_matched_line_num $line_num
        incr conf_num 1
        # when it was last pattern to match
        if {$conf_num == $conf_size} { break }
    }
  }
  return [list $conf_num $last_matched_line_num]
}

# ===================================================================== #
# list all results in form of table or sql
# ===================================================================== #
proc print_results {SQL_FLAG} {

  # setup formatting style
  set COL_NUM [ expr $CONFIG::report_col_num - 1 ]
  set FIELD_SIZE $CONFIG::report_field_size

  # if specified add m_id column from command line
  if {$::m_id_flag == 1} {
        lappend cols [ format "%${FIELD_SIZE}s" "m_id" ]
        lappend vals [ format "%${FIELD_SIZE}s" "$::m_id_val" ]
  }

  foreach v [ get_varnames ] {
    foreach t [ split $v ] {
      if {[info exists ::$t]} {
        lappend cols [ format "%${FIELD_SIZE}s" "$t" ]
        lappend vals [ format "%${FIELD_SIZE}s" "[set ::$t]" ]
      }
    }
  }

  if {$SQL_FLAG == 0} {
    set i 0
    foreach n $cols v $vals {
      incr i 1
      puts [format "%3d.  %s  %s" "$i" "$n" "$v" ]
    }
  } else {
    # create table
    set col_table ""
    set val_table ""
    set cols_sz [ llength $cols ]
    for {set i 0 } {$i < $cols_sz} { incr i $COL_NUM } {
      set j [ expr $i + $COL_NUM ]
      set val_range [ lrange $vals  $i $j ]
      set val_row [ join $val_range , ]
      set col_range [ lrange $cols $i $j ]
      set col_range_sz [ llength $col_range ]
      set col_row [ join $col_range , ]

      # if neccessary add "," at the end of the rows
      if {$col_range_sz == [expr $COL_NUM +1] && $j < $cols_sz} {
        set col_row "$col_row," 
        set val_row "$val_row," 
      }

      # add row to the table
      lappend col_table $col_row
      lappend val_table $val_row
    }
    # put \n after each row
    set col_table "[ join $col_table \n ]"
    set val_table "[ join $val_table \n ]"

    set ::table_name [ join [ split $::process_name ] "_" ]
    puts "INSERT INTO $::table_name (\n$col_table \n) VALUES(\n$val_table \n);"
   }
}

# ===================================================================== #
proc main {} {

  if {$::argc==0} {
    puts stderr "Parse $::process_name process logfile and generate report\n"
    puts stderr "Usage: $::argv0 <-s> <-m_id rowid>  filename.$::ext_pat"
    puts stderr "\t -s             = generate sql query"
    puts stderr "\t -m_id  rowid   = insert m_id column"
    puts stderr "\t filename.$::ext_pat = report file from $::process_name process."
    exit 1
  } 

  # initialize global variable
  set ::SQL_FLAG 0
#  set ::ROWID    ""

  # setup configuration patterns
  if {! [ info exists ::config ] } {
    puts stderr "Configuration \$config not specified." 
    return 0
  }
  set conf_size [ expr [ llength $::config ] / 2 ]
  if { $conf_size == 0 } {
    puts stderr "Configuration is empty!"
    return 0; 
  }
  set conf_num 0

  # initialize variables to "null"
  foreach v [ get_varnames ] {
    foreach varname [ split $v ] {
      global $varname 
      set $varname "null"
      # puts "$varname [ set $varname ]"
    }
  }

  # parse arguments & read data from logfile
  set fname [ parse_args $::argv ]
  set fid [ open $fname ]
  set logdata [ read $fid ]
  close $fid

  # parse logdata
  set line_num 0
  while { $conf_num < $conf_size } {
    # try to match as many as possible
    set lres [ parse $logdata $line_num $conf_num $conf_size ]
    set conf_num [ lindex $lres 0 ]
    set new_line_num [ lindex $lres 1 ]
    # puts [ format "return:  line_num = %3d  conf_num = %3d"  "$new_line_num" "$conf_num" ]
    incr conf_num 1

    if {$new_line_num != 0 } {
      set line_num $new_line_num
    }
  }

  # correct results if neccessary
  foreach v [ get_varnames ] {
    foreach t [ split $v ] {
      if {[regexp {^(n|t)} $t ] } {
        global $t
        set val [ set $t ]
        if { ! [ regexp {[\d\.]} $val ] } {
          set $t -1
        }
      }
    }
  }

  print_results $::SQL_FLAG

  # if not all patterns were found
  #if {$conf_num != $conf_size} {
  #  set l [ get_patval $conf_num]
  #  set pat [lindex $l 0 ]
  #  puts "# Parser failed at pattern $conf_num:\n $pat"
  #}
}


# ===================================================================== #
#         Main 
# ===================================================================== #
set homedir   "[get_homedir]"
set rootlevel "$homedir/$PATH_LEVEL"
source "$rootlevel/_conf.tcl"
source "$homedir/utils_api.tcl"

# If this script was executed, and not just "source"'d, handle argv
set linked_fname [ is_linked [info script ]]
if { [ string compare $linked_fname "" ] != 0 || [string compare [info script] $argv0] == 0} { 
  if {$::argc==0} {
    puts stderr "Usage: $argv0 filename"
    puts stderr "\t -s         = generate sql query" 
    puts stderr "\t -p         = name of the process" 
    puts stderr "\t -e         = file extension" 
    puts stderr "\t filename   = logfile file from process "
    exit 1
  } 
  main
}
