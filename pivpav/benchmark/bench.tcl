#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

set PATH_LEVEL "../"

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
proc mkdir {} {
  if {$::NO_WRAP== 1 } {
      puts [ format "* %-40s" "skipped" ]
      return 
  }
  set ::savePWD [ pwd ]
  if { [ file isdirectory $::WORKDIR ] } {
    puts -nonewline "(recreated)"
    file delete -force $::WORKDIR
  } 
  file mkdir $::WORKDIR
  puts " $::WORKDIR"
}

# ===================================================================== #
# create vhdl file with wrapped component
proc create_vhdl {} {
  if {$::NO_WRAP == 1 } {
    puts [ format "* %-40s" "skipped" ]
    return
  }
  set opt "-d $::DBNAME -x $::ROWID -r -n $::CLOCK_FREQ -u $::UCFFILE > $::VHDLFILE"
  set cmd "$::WRAPPER_BIN $opt "
  puts $::db_fid "M_WRAPPER_CMD_OPT \"$opt\"" ; flush $::db_fid
  puts [ format "\t %15s %s" "Command: " "$cmd" ]

  set t0 [ ::UTILS::time_mark ]
  set rc [ catch {eval "exec $cmd"} errmsg ]
  puts $::db_fid "M_WRAPPER_CPU_TIME [ ::UTILS::time_from_now $t0 ]" 
  exec sync
  if { $rc==1 && [ string compare $::errorCode "NONE" ]!=0 } {
    puts stderr "\nError when executing command:\n-> $cmd \n-> $stderr_msg"
    puts $::db_fid "M_WRAPPER_ERROR 1" ; flush $::db_fid
    exit 1
  }
  puts [ format "\t %15s %s" "Generated: " "$::UCFFILE ($::CLOCK_FREQ ns) $::VHDLFILE" ]
  puts $::db_fid "M_WRAPPER_ERROR 0" ;  flush $::db_fid
}

# ===================================================================== #
proc extract_files  { } {
  if {$::NO_WRAP == 1 } {
    puts [ format "* %-40s" "skipped" ]
    return
  }
  set save_pwd [pwd]
  cd $::WORKDIR

  set opt "-d $::DBNAME $::ROWID"
  set cmd_d "$::CONFIG::db_extr_cir_file_rel $opt"
  puts [ format "\t %15s %s" "Command: " "$cmd_d" ]
  puts $::db_fid "M_EXTRACT_CMD_OPT \"$opt\"" ; flush $::db_fid

  set t0 [ ::UTILS::time_mark ]
  set rc [ catch {set outfile [ exec  $::CONFIG::db_extr_cir_file_full -d $::DBNAME $::ROWID ] } stderr_msg ]
  puts $::db_fid "M_EXTRACT_CPU_TIME [ ::UTILS::time_from_now $t0 ]" 
  if { $rc == 1 && [ string compare $::errorCode "NONE" ] != 0 } {
    puts stderr "\nError when executing command:\n-> $cmd_d\n-> $stderr_msg"
    puts $::db_fid "M_EXTRACT_ERROR 1" ; flush $::db_fid
    exit 1
  }
  puts $::db_fid "M_EXTRACT_ERROR 0" ; flush $::db_fid

  # wait till file is created and has size
  exec sync
  while {[ file size $outfile ] == 0 } { 
    after 500 
  }

  puts [ format "\t %15s %s" "Extacted: " "$::WORKDIR/${outfile} (size:[ file size $outfile ])" ]
  cd $save_pwd
}


# ===================================================================== #
# compile source files with ise
proc compile {} {
  if {$::NO_COMPILE== 1 } {
      puts [ format "* %-40s" "skipped" ]
      return 
  }

  set flist [ glob -directory "$::WORKDIR" *.{vhd,vhdl,ucf,ngc} ]
  set cmd "$::CONFIG::ise_file_full -dir $::ISEDIR -goal $::CONFIG::ise_design_goal_default -logfile $::ISELOGFILE $flist"
  puts [ format "\t %15s %s" "Command: " "$cmd" ]

  set t0 [ ::UTILS::time_mark ]
  set fid [ open "|$cmd 2>@stdout" r ]
  fconfigure $fid -blocking false
  set error_msg ""
  set isError 0
  while { ![eof $fid]} { 
    set line [ read $fid ]
    if {[ regexp {^ERROR:} $line ]  } {
      puts stderr "\n\n$line"
      # puts stderr "\n\nERROR occured - try to decrease frequency? DO YOU HAVE A LICENSE KEY?"
      puts $::db_fid "M_ISE_ERROR 1" ; flush $::db_fid
      set isError 1
    } else {
      puts -nonewline $line
    }
  }
  close $fid
  puts $::db_fid "M_ISE_CPU_TIME [ ::UTILS::time_from_now $t0 ]" ; flush $::db_fid

  #  copy contents of ise_db_api when finished
  set ise_fid [ open "$::ISEDIR/$::CONFIG::ise_db_api_file" ]
  set ise_db_data [ read $ise_fid ]
  close $ise_fid
  foreach line [ split $ise_db_data "\n" ] { 
    if { [ string compare $line "" ] == 0 } { 
      continue
    }
    puts $::db_fid "M_${line}"
  }


  if { $isError } { exit 1 }

  puts $::db_fid "M_ISE_ERROR 0" ; flush $::db_fid
}

# ===================================================================== #
proc store_project {} {
    set proj_files [ ::UTILS::compress_tgz $::WORKDIR ]

    set rc [ catch {
      sqlite3 db $::DBNAME
      db eval { BEGIN TRANSACTION; }
#      db eval "INSERT INTO measure(p_ops_id, design_goal, projfiles) VALUES($::ROWID, '$::CONFIG::ise_design_goal_default', @proj_files);"
      set ::M_ROWID [ db eval { SELECT last_insert_rowid() } ] 
      db eval { COMMIT; }
      db close
    } stderr_msg ]

    if { $rc != 0 } {
      puts stderr "\n Error when inserting data to database:\n-> $stderr_msg"
      exit 1
    }

}

# ===================================================================== #
proc usage {} {
    upvar #0 argv0 argv0
    puts stderr "Wrap and compile given component."
    puts stderr "  1. get component from database"
    puts stderr "  2. wrap it with other component (instantiate him)"
    puts stderr "  3. compile (synthesize, map, par..)"
    puts stderr "  4. parse logfiles and store results into database\n"
    puts stderr "Usage: $argv0  <parameters> <flags> rowid"
    puts stderr "\t parameters:"
    puts stderr "\t  -no_wrap    = do not wrap design, compile only"
    puts stderr "\t  -no_compile = do not compile design"
    puts stderr "\t  -no_res     = do not parse logfiles for results"
    puts stderr "\t  -stdout     = print results to stdout instead of inserting them to db"
    puts stderr "\t  -no_ngc     = there is no ngc (used when there is vhdl instead)"
    puts stderr "\t flags:"
    puts stderr "\t  -g goal     = design goal           (default: $::CONFIG::ise_design_goal_default)"
    puts stderr "\t  -w dir      = wrapper directory     (default: $::WORKDIR)"
    puts stderr "\t  -n freq     = design clock freq     (default: $::CLOCK_FREQ)"
    puts stderr "\t  -l file     = compilation logfile   (default: $::ISELOGFILE)"
    puts stderr "\t  -u file     = ucf file              (default: $::UCFFILE)"
    puts stderr "\t  -v file     = vhdl file             (default: $::VHDLFILE)"
    puts stderr "\t  -d file     = database file         (default: $::DBNAME)"
}

# ===================================================================== #
proc parse_args {} {
  global WORKDIR
  global ISELOGFILE
  global UCFFILE
  global VHDLFILE
  global DBNAME
  global ROWID
  global NO_COMPILE
  global NO_WRAP
  global NO_RES
  global STDOUT
  set ::NO_NGC 0

  set size [ llength $::argv ]
  for {set i 0} {$i < $size} {incr i 1} {
    set flag [lindex $::argv $i ]
    set val  [lindex $::argv [ expr $i+1 ] ]

    switch -- $flag {
      "-no_ngc" { set ::NO_NGC 1 }
      "-stdout" {
        set STDOUT 1
      }
      "-no_res" {
        set NO_RES 1
      }
      "-no_compile" {
        set NO_COMPILE 1
      }
      "-no_wrap" {
        set NO_WRAP 1
      }
      "-w" {
        set pwd ""
        if { !  [regexp {^/} $val {} ] } { set pwd "$::CONFIG::measure_dir_full/" }
        set WORKDIR "${pwd}${val}"
        incr i 1
      }
      "-l" {
        set ISELOGFILE $val
        incr i 1
      }
      "-u" {
        set UCFFILE $val
        incr i 1
      }
      "-v" {
        set VHDLFILE $val
        incr i 1
      }
      "-d" {
        set pwd ""
        if { !  [regexp {^/} $val {} ] } { set pwd "[pwd]/" } 
        set DBNAME "$pwd$val"
        incr i 1
      }
      "-n" {
        set ::CLOCK_FREQ $val
        incr i 1
      }
      "-g" {
        set ::CONFIG::ise_design_goal_default $val
        incr i 1
      }
      default {
        set ROWID $flag
        break;
      }
    }
  }

  if {[ string compare $ROWID "" ] == 0 } {
    puts stderr "ROWID not found"
    exit
  }
  if {[regexp {\d+} $ROWID] } {

  } else {
    puts stderr "Invalid ROWID: '$ROWID'. It is not an number!" 
    exit
  }

  update_files $::WORKDIR
}


# ===================================================================== #
proc update_files {wrkdir} {
  set ::ISEDIR     "$wrkdir/ise"
  set ::UCFFILE    "$wrkdir/top.ucf"
  set ::VHDLFILE   "$wrkdir/top.vhd"
  set ::ISELOGFILE "$wrkdir/ise.log"
}


proc vars_setup {} {
  set ::DBNAME     "$CONFIG::db_file_full"
  set ::WORKDIR    "$CONFIG::measure_dir_full"
  set ::ISEDIR     "$::WORKDIR/ise_full"
  set ::ROWID      ""

  set ::comment      "$CONFIG::comment_line"
  set ::WRAPPER_BIN  "${::CONFIG::wrapper_bin_file_full}"
  set ::CLOCK_FREQ   "${::CONFIG::wrapper_clock_freq}"
  set ::NO_COMPILE 0
  set ::NO_WRAP    0
  set ::NO_RES     0
  set ::STDOUT     0

  update_files $::WORKDIR
}

# ===================================================================== #
# main
# ===================================================================== #
set rootlevel "[get_homedir]/$PATH_LEVEL"
source "$rootlevel/_conf.tcl"
source ${::CONFIG::utils_file_full}
vars_setup

# If this script was executed, and not just "source"'d, handle argv
set linked_fname [ is_linked [info script ]]
if { [ string compare $linked_fname "" ] != 0 || [string compare [info script] $argv0] == 0} { 
  if {$argc == 0} { 
    usage
    exit
  }
  parse_args

  puts "$::comment"
  puts -nonewline [ format "* %-50s" "Creating directory:" ]
  flush stdout 
  set t0 [ ::UTILS::time_mark ]
  mkdir
  set t_end [ ::UTILS::time_from_now $t0]

  set ::CONFIG::measure_db_api_file "$::WORKDIR/$::CONFIG::measure_db_api_file"
  set ::db_fid [ open $::CONFIG::measure_db_api_file w ]
  puts $::db_fid "_DB_FNAME $::DBNAME"
  puts $::db_fid "_M_F_KEY $::WORKDIR"
  puts $::db_fid "M_C_KEY $::ROWID"
  puts $::db_fid "M_GOAL $::CONFIG::ise_design_goal_default"
  puts $::db_fid "M_FREQ $::CLOCK_FREQ"
  puts $::db_fid "M_CMD_OPT \"$argv\"" 
  puts $::db_fid "M_DIR_ERROR 0" 
  puts $::db_fid "M_DIR_CPU_TIME $t_end" 
  flush $::db_fid


  puts "$::comment"
  puts [ format "* %-50s" "Creating wrapped design" ]
  flush stdout 
  create_vhdl

  puts "$::comment"
  puts [ format "* %-50s" "Extracting files from DB" ]
  flush stdout
  #if { $NO_NGC } { 
  #  extract_files vhdl
  #} else {
  #  extract_files ngc
  #}
  extract_files

  puts "$::comment"
  puts [ format "* %-50s" "Design compilation" ]
  compile 


#  puts [ format "* %-50s" "Storing all generated files into DB" ]
#  store_project

#  puts "$::comment"
#  puts -nonewline [ format "* %-50s" "Parsing logfiles & storing results to DB" ]
#  parse_logfiles

}
