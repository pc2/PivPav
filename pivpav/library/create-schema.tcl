#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

set PATH_LEVEL ".."

# ===================================================================== #
# if script is linked then get script name and path

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
  global db_flag 
  global db_fname
  set db_flag 0

  set size [ llength $argv ]
  for {set i 0} {$i < $size} {incr i 1} {
    set flag [lindex $argv $i ]
    set val  [lindex $argv [ expr $i+1 ] ]

    switch -- $flag {
      "-d" {
        set db_flag 1
        set db_fname [ lindex $argv $i ]
        incr i 1
      }
      default {
        puts stderr "Error while parsing arguments."
        usage
        exit 1
      }
    }
  }
}

# ===================================================================== #
proc usage {} {
    upvar #0 argv0 argv0
    puts stderr "Generate whole schema (structure) for sqlite database.\n"
    puts stderr "Usage: $argv0 <-d fname>"
    puts stderr "\t -d         = send sql into database (default: $::db_fname)"
}

# ===================================================================== #
#         Main 
# ===================================================================== #
source           "[get_homedir]/$PATH_LEVEL/_conf.tcl"
set reports_dir  "$::CONFIG::report_dir_full"
set db_fname     "$::CONFIG::db_file_full"

set linked_fname [ is_linked [info script ]]
if { [ string compare $linked_fname "" ] != 0 || [string compare [info script] $argv0] == 0} { 

  parse_args $::argv

  # read sql schema from file to variable
  set fp  [ open "$::CONFIG::db_sql_schema_file_full" ] 
  set sql_schema [ read $fp ]
  close $fp

  set fp  [ open "${::CONFIG::db_sql_view_file_full}" ] 
  set sql_view [ read $fp ]
  close $fp

  # generate schema for reports
  set rep_sql [ exec xtclsh ${::CONFIG::report_schema_file_full} -a ]
  
  if {$db_flag == 1} {
    # connect to database and execute sql code
    sqlite3 db $db_fname
    db eval {BEGIN TRANSACTION; }
    db eval $sql_schema
    db eval $rep_sql;
    # db eval $sql_view;
    db eval {COMMIT; } 
  } else {
    puts "-- configuration read from file: ${::CONFIG::db_sql_schema_file_rel}"
    puts $sql_schema
    puts $rep_sql
    # puts $sql_view
  }
}
