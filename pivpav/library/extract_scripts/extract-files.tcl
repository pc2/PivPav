#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh
# #!/Xilinx/ISE92i/bin/lin/xtclsh

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
proc parse_args {argv} {
  set ::DB_FLAG 0
  set ::ROWID -1
  set ::TABLE_FLAG 0
  set ::TABLE_NAME ""
  set ::COL_FLAG 0
  set ::COL_NAME ""
  set ::FILE_MASK ""
  set ::STDOUT 0
  set ::RES_FILE 0
  set ::DST_DIR_FLAG 0
  set ::DST_DIR "./"

  set size [ llength $argv ]
  for {set i 0} {$i < $size} {incr i 1} {
    set flag [lindex $argv $i ]
    set val  [lindex $argv [ expr $i+1 ] ]

    switch -- $flag {
      "-d" {
        set ::DB_FLAG 1
        set ::CONFIG::db_file $val; 
        set_full_path db_file
        incr i 
      }
      "-C" {
        set ::DST_DIR_FLAG 1
        set ::DST_DIR $val
        incr i
      }
      "-t" {
        set ::TABLE_FLAG 1
        set ::TABLE_NAME $val
        incr i 1
      }
      "-c" {
        set ::COL_FLAG 1
        set ::COL_NAME $val
        incr i 1
      }
      "-e" {
        set ::FILE_MASK $val
        incr i 1
      }
      "-f" {
        puts "-f currently not supported"
        set ::RES_FILE $val
        incr i 1
      }
      "-stdout" {
        set ::STDOUT 1 
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

  if { [ string compare $::TABLE_NAME "" ] == 0 } {
    puts stderr "ERROR: table not specified"
    exit
  }

  if { [ string compare $::COL_NAME "" ] == 0 } {
    puts stderr "ERROR: column not specified"
    exit
  }

  if { !  [ file exists $::CONFIG::db_file_full ] }   {
    puts stderr "ERROR: Database file does not exists: $::::CONFIG::db_file_rel";
    exit 1
  }
  if { [ string compare $::FILE_MASK "" ] } {
    set ::FILE_MASK "*.${::FILE_MASK}"
  }
}


# ===================================================================== #
proc usage {} {
    upvar #0 argv0 argv0
    puts stderr "Extract file from database.\n"
    puts stderr "Usage: $argv0 <options> <-d fname> -t table -c column rowid"
    puts stderr "\t -d         = database file (default: $::CONFIG::db_file)"
    puts stderr "\t -t         = table name" 
    puts stderr "\t -c         = column name" 
    puts stderr "options:"
    puts stderr "\t -e         = extension file mask (default *)"
    puts stderr "\t -C         = destination directory"
    puts stderr "\t -stdout    = extract to stdout"

#    puts stderr "\t -f         = extract file to operator name"
}

# ===================================================================== #
proc extract {} {
  # prepare directory
  if { $::DST_DIR_FLAG == 1 } { 
    file mkdir ${::DST_DIR}
    cd ${::DST_DIR}
  }


  # fetch compressed data from db
  sqlite3 db $::CONFIG::db_file
  # read blob from db
  set blob_fid [ db  incrblob -readonly $::TABLE_NAME $::COL_NAME $::ROWID ]
  fconfigure $blob_fid -translation binary -buffering none
  # uncompress
  set outfile ""
  ::UTILS::uncompress_tgz [ read $blob_fid ] $::FILE_MASK $outfile $::STDOUT
  close $blob_fid
  exec sync 
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
parse_args $::argv
# do the job
extract
