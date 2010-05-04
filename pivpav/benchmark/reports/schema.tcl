#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

set PATH_LEVEL "../.."

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
proc gen_sql {} {
  set FIELD_SIZE 20
    set p [ join [ split $::process_name  ] _ ]
    
    set short [ lindex [ regexp -inline {(\S\S\S)} $p ] 0 ]
    puts "CREATE TABLE $p ("
    puts [ format "\t%-${FIELD_SIZE}s  %s," "${short}_key" "INTEGER PRIMARY KEY" ]
    puts [ format "\t%-${FIELD_SIZE}s  %s," "m_id" "INTEGER" ]
    puts [ format "\t%-${FIELD_SIZE}s  %s," "repfile" "BLOB" ]
    set row ""
    foreach v [ get_varnames ] {
      foreach t [ split $v ] {
        set type ""
          if {[ regexp {^(n|t)} $t {} ]}  { 
            set type "REAL" 
          } else  {
            set type "VARCHAR" 
          }
        lappend row  [ format "\t%-${FIELD_SIZE}s  %s" "$t" "$type" ]
      }
    }
  set table [ join $row ",\n" ]
    puts $table
    puts ");"
}

# ===================================================================== #
proc parse_args {argv} {
  set rep_file ""
  global all_flag 
  set all_flag 0

  set size [ llength $argv ]
  for {set i 0} {$i < $size} {incr i 1} {
    set flag [lindex $argv $i ]
    set val  [lindex $argv [ expr $i+1 ] ]

    switch -- $flag {
      "-a" {
        set ::all_flag 1
      }
      default {
        set fname $flag
        if {[ file isfile $fname ] == 0 } {
          puts stderr "File: '$fname' does not exists"
          exit 1
        }
        lappend rep_file $fname
      }
    }
  }
  return $rep_file
}

# ===================================================================== #
#         Main 
# ===================================================================== #
# If this script was executed, and not just "source"'d, handle argv

if { [string compare [info script] $argv0] == 0} {
  if {$::argc==0} {
    puts stderr "Generate schema for sqlite database based on variable names"
    puts stderr "used for regular expressions in files report_*.tcl\n"
    puts stderr "Usage: $argv0 <-a> filenames"
    puts stderr "\t -a         = generate for all report_*.tcl" 
    puts stderr "\t filename   = file with regexp configuration"
    exit 1
  } 


  set fnames [ parse_args $::argv ]
  if {$::all_flag == 1} {
    set fnames [ glob -directory [get_homedir] report_*.tcl ]
  } 

  foreach f $fnames {
    source $f
    puts "-- configuration read from file: $f"
    gen_sql
  }
}
