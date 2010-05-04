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
proc usage {} {
    upvar #0 argv0 argv0
    puts stderr "Extract file from database for given circuit.\n"
    puts stderr "Usage: $argv0 <-d fname> rowid"
    puts stderr "\t -d         = database file (default: $::CONFIG::db_file)"
    puts stderr "\t -e         = extension mask (default: *)"

}
# ===================================================================== #
proc parse_args {} {
  set ::FILE_MASK "*"

  set size [ llength $::argv ]
  for {set i 0} {$i < $size} {incr i 1} {
    set flag [lindex $::argv $i ]
    set val  [lindex $::argv [ expr $i+1 ] ]

    switch -- $flag {
      "-d" {
        set ::DB_FLAG 1
        set ::CONFIG::db_file $val; 
        set_full_path db_file;
        incr i 
      }
      "-e" {
        set ::FILE_MASK $val
        incr i
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

  if { !  [ file exists $::::CONFIG::db_file_full ] }   {
    puts stderr "ERROR: Database file does not exists: $::::CONFIG::db_file_rel";
    exit 1
  }

  if { ! $::ROWID }  {
    puts stderr "ERROR: no rowid"
    usage
    exit 1
  }
}

# ===================================================================== #
proc extract {} {
  # get the f_key
  sqlite3 db $::CONFIG::db_file
  set f_key [ db eval { select cir_f_res_key from circuit where cir_key = $::ROWID } ]
  puts [ exec ${::CONFIG::db_extr_file_full} -e $::FILE_MASK -d $::CONFIG::db_file_full -t file -c f_store $f_key ]
}

# ===================================================================== #
#         Main 
# ===================================================================== #

set rootlevel_dir "[get_homedir]/$PATH_LEVEL"
source "$rootlevel_dir/_conf.tcl"
source $::CONFIG::utils_file_full

# default setting
if {$argc == 0 } {
  usage
  exit 1
}

# setting parameters
parse_args
# do the job
extract
