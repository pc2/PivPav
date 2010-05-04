#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

set PATH_LEVEL ".."
# ===================================================================== #
proc filelist {dir ext} {
    set result [list]
    foreach e $ext {
      set tmp [ UTILS::find_file "$dir/*.$e" ]
      if {[ llength $tmp ] != 0 } { lappend result $tmp }
    }
    return $result 
}
proc parse_repfile {} {


  if { $::f_flag == 1 } {
    file delete $::f
  }

  foreach m_vname [info vars CONFIG::report*mask ] {
    set f_vname [ regsub {mask} $m_vname file_full ]
    set fname [ set $f_vname ]
    set ext   [ set $m_vname ]
    set repfile [ filelist $::src_dir $ext ]

    if { [ string compare $repfile "" ] == 0 } { 
      puts stderr "\nError report file '$::src_dir/*.$ext'  not found"
      exit
    }

    # execute & get results
    set cmd {set results [ exec $fname -s -m_id $::m_id $repfile ] }
    set rc [ catch { eval $cmd } stderr_msg ]
    if { $rc != 0 } {
      puts stderr "\nError when executing command:\n-> $fname -s $repfile\n-> $stderr_msg"
      exit 1
    }


      # get table name
      set table_name ""
      regexp {INSERT\s+INTO\s+(\S+)} $results {} table_name
      if {[ string compare $table_name "" ] == 0 } {
        puts stderr "Error table name not found in sql statement:\n $results"
        exit
      }
      # 3 letters from table_name + "_key" = talbe key column
      set table_key ""
      regexp {(\S\S\S)} $table_name {} table_key
      if {[ string compare $table_key "" ] == 0 } {
        puts stderr "Error key columnt not found for $table_name"
        exit
      } else {
        set table_key "${table_key}_key"
      }

      if { $::f_flag == 1 } {
        set fid [ open $::f a ]
        puts $fid $results
        close $fid
        continue
      }

      # compress repfile
      set file_blob [ ::UTILS::compress_tgz "$repfile" ]

      set rc [ catch {
        sqlite3 db $::CONFIG::db_file
        db eval { BEGIN TRANSACTION; }
        # insert report into db
        db eval $results
        # get rowid of that
        set rowid [ db eval { SELECT last_insert_rowid() } ] 
        # store compressed report file
        db eval "UPDATE $table_name SET repfile = @file_blob where $table_key = $rowid"
        db eval { COMMIT; }
        } stderr_msg ]
      if { $rc != 0 } {
        puts stderr "\n Error when inserting data to database:\n-> $stderr_msg"
        exit 1
      }
    }
}
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

proc usage {} {
  puts "[info script] <-debug> -db fname -m_id dir " 
  puts "\t dir                   : generate reports for the ISE project from this dir"
  puts "\t -f      fname         : store sql to file instead to db"
  puts "\t -db     fname         : database file name"
  puts "\t -m_id   rowid         : rowid of m_id column"
  puts "\t -debug                : enable debugging mode"
  puts ""
}

proc parse_args {} {
  set ::db_flag 0
  set ::m_id 0
  set ::f_flag 0
  set ::f ""
  set ::src_dir ""


  set size [ llength $::argv ]
  for {set i 0} {$i < $size} {incr i 1} {
    set flag [lindex $::argv $i ]
    set val  [lindex $::argv [ expr $i+1 ] ]

    switch -- $flag {
      "-db" {
        set ::db_flag 1
        set ::CONFIG::db_file $val
        set_full_path db_file
        incr i 1
      }
      "-f" {
        set ::f_flag 1
        set ::f $val
        incr i 1
      }
      "-m_id" {
        set ::m_id $val
        incr i 1
      }
      "-debug" {
        set ::DEBUG 1
      }
      default {
          set ::src_dir [ lindex $::argv $i]
          incr i
          break;
      }
    }
  }

  if {[string compare $::src_dir ""] == 0} {
    puts stderr "Directory not specified.\n"
    usage
    exit 1
  }
  if { [ file isdirectory $::src_dir ] == 0 } {
    puts stderr "Directory: '$::src_dir' does not exists."
    exit 1
  }
  if { $::db_flag == 0 } {
    puts stderr "Please specify db"
    exit 1
  }
  if { $::m_id == 0 } {
    puts stderr "Please specify m_id"
    exit 1
  }
}
# ===================================================================== #
# main
# ===================================================================== #
set rootlevel "[get_homedir]/$PATH_LEVEL"
source "$rootlevel/_conf.tcl"
source ${::CONFIG::utils_file_full}

set linked_fname [ is_linked [info script ]]
if { [ string compare $linked_fname "" ] != 0 || [string compare [info script] $argv0] == 0} { 
  if {$argc == 0} { 
    usage
    exit
  }
  parse_args
  parse_repfile
}

