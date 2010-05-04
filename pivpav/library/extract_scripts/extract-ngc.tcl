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
  set ::DB_FLAG 0
  set ::ROWID -1

  set size [ llength $argv ]
  for {set i 0} {$i < $size} {incr i 1} {
    set flag [lindex $argv $i ]
    set val  [lindex $argv [ expr $i+1 ] ]

    switch -- $flag {
      "-d" {
        set ::DB_FLAG 1
        set ::DB_FNAME $val
        incr i 1
      }
      default {
        if {[regexp {^\d+$} $flag ]} {
          set ::ROWID $flag
        } else {
          puts stderr "Error while parsing arguments."
          usage
          exit 1
        }
      }
    }
  }
}


# ===================================================================== #
proc usage {} {
    upvar #0 argv0 argv0
    puts stderr "Extract ngc file from  database.\n"
    puts stderr "Usage: $argv0 <-d fname> rowid"
    puts stderr "\t -d         = database file (default: $::DB_FNAME)"
}

# ===================================================================== #
proc extract {} {
  # open database
  sqlite3 db $::DB_FNAME

  # check if there is something in there
  set not_null [ db eval { select length(hex(projfiles)/2) from operator where op_key = $::ROWID; } ] 
  puts "result: $not_null"
  if { [ string compare $not_null "" ] == 0 } {
    puts stderr "There are no data for $::DB_FNAME/operator/$::ROWID/projfiles"
    exit 13
  }
  # read blob from db
  set blob_fid [ db  incrblob -readonly operator projfiles $::ROWID ]
  fconfigure $blob_fid -translation binary -buffering none
  set blob_data [ read $blob_fid ]
  close $blob_fid

  # get filename for blob
  set op_name [ db eval { select op_name from operator where op_key = $::ROWID } ]

  # store blob to file
  uncompress_tgz $blob_data "*.ngc" "$op_name.ngc"
  exec sync

  puts $op_name.ngc
}

# ===================================================================== #
#         Main 
# ===================================================================== #

set rootlevel_dir "[get_homedir]/$PATH_LEVEL"
source "$rootlevel_dir/_conf.tcl"
source "$rootlevel_dir/utils_api.tcl"


# default setting
set ::DB_FNAME "$PATH_LEVEL/$CONFIG::db_file"
if {$argc == 0 } {
  usage
  exit 1
}

# setting parameters
parse_args $::argv
if { [ string compare $::DB_FNAME "" ] == 0 } {
  set ::DB_FNAME "[get_homedir]/$PATH_LEVEL/$CONFIG::db_file"
}

extract
