#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

set PATH_LEVEL "../"

# ===================================================================== #
#  * xilinx msg  -> stdout -> logfile
#  * this script -> stderr -> screen
#
# Xilinx uses stdout for printing msg's. It does not use "puts" for that.
# Therefor we can't wrap it in other command.
#
# To distinguesh messages btw this script and xilinx msg in this script
# we are using stderr.
# That allows us to close stdout (xilinx msg) and reopen it to file.
# ===================================================================== #


proc redirect_stdout {fname} {
  upvar #0 stdout stdout
  close stdout
  set stdout [ open "$fname" w ]
  fconfigure stdout -buffering none
  puts stderr [ format "* %-40s %s" "Logfile:" "$fname" ]
}


# ===================================================================== #
proc mkdir { dir } {
  if {![file isdirectory $dir]} {
    # file delete -force $dir
    puts stderr [ format "* %-40s %s" "Creating directory" "$dir" ]
    file mkdir $dir
  }
}
# ===================================================================== #
proc prj_create { dir } {
  redirect_stdout $::logfile

  if {[file isfile "$dir/proj.ise" ]} {
    puts stderr [ format "* %-40s %s" "File exists - opening:" "$dir/proj.ise" ]
    project open $dir/proj.ise
  } else {
    puts stderr [ format "* %-40s %s" "Changing directory to:" "$dir" ]
    puts stderr [ format "* %-40s %s" "Creating new ISE project:" "$dir/proj.ise" ]
    project new $dir/proj.ise


    foreach  {param val} "\
      family  $SET::_devicefamily   \
      device  $SET::_device         \
      package $SET::_package        \
      speed $SET::_speedgrade       \
      top_level_module_type HDL \
      synthesis_tool {XST (VHDL/Verilog)} \
      simulator {Modelsim-SE Mixed} \
      {Preferred Language} VHDL \
      {Enable Message Filtering} false \
      {Display Incremental Messages} false" {
        puts stderr [ format "* %-40s %s" "Property '$param'" "= '$val'"]
        project set $param $val
    }
 }
}

# ===================================================================== #
proc prj_addfiles { dir flist} {
  foreach f $flist {
    set fname [ file tail $f ]

    # puts stderr "dir=$dir file=$f  fname=$fname"
    # it's not found when xfile get writes to STDERR
    # if it does we can add it
    set rc [ catch { xfile get $fname name } msg ]
    if { $rc == 1 } {
      puts stderr [ format "* %-40s %s" "Adding file to project:" "$f" ]
      if { [ regexp {^/} $f ] } {
        xfile add "$f"
      } else { 
        xfile add "$dir/$f"
      }
    } else {
      puts stderr [ format "* %-40s %s" "File exists in  project:" "$f" ]
    }
  }
}


# ===================================================================== #
proc prj_properties { ngcPath } {
 # project set top "arch" "top"
  if {[string compare $ngcPath ""] != 0} {
    project set "Macro Search Path" "$ngcPath" -process "Translate"
  }

  set goal_file "$::CONFIG::ise_design_goal_dir_full/${::CONFIG::ise_design_goal_default}.tcl"
  if { [ file exists $goal_file ] == 1 } {
    puts stderr [ format "* %-40s %s" "Design goal" "$::design_goal" ]
    source $goal_file
  } else {
    puts stderr "Design goal file not found: $goal_file"
    exit 1
  }
}

# ===================================================================== #
proc prj_compile { cmds }  {
  set cmds_size [ llength $cmds ]
  set i 0
  foreach proc_name $cmds {
    incr i
    puts stderr [ format "* %-40s %s" "\[$i/$cmds_size\] task:" "$proc_name"]

    regsub -all { |-|&} $proc_name {_} proc_name_db
    regsub -all {_+} $proc_name_db {_}  proc_name_db
    set proc_name_db [ string toupper $proc_name_db ]

    # puts -nonewline stderr "        "
    # unfortunatelly it returns always true
    set t0 [ ::UTILS::time_mark ]
    set rc [ catch { process run $proc_name } msg ]
    puts $::db_fid "ISE_RUN_${proc_name_db}_CPU_TIME [ ::UTILS::time_from_now $t0 ]" ; flush $::db_fid
    if { $rc == 1 } {
      if { [ string compare $::errorCode "ERUN" ] == 0 } {
        puts stderr "ERROR: process '$proc_name' failed!"
        project close
        puts $::db_fid "ISE_RUN_${proc_name_db}_ERROR 1"; flush $::db_fid
        puts $::db_fid "ISE_RUN_ERROR 1"; flush $::db_fid
        close $::db_fid
        exit 1
      }
    }
    puts $::db_fid "ISE_RUN_${proc_name_db}_ERROR 0" ; flush $::db_fid
  }
}


# ===================================================================== #
proc prj_results { reportfile} {
  if { ! [ catch { set latency [ exec grep -i "frequency" $reportfile ]} errmsg ] } {
      puts stderr "        $latency"
   }
}


# ===================================================================== #
proc parse_args {argv} {
  set dir ""
  set logfile ""
  set isXCO 0
  set isVHDL 0
  set ngcPath ""
  set srcs "" 
  set size [ llength $argv ]
  set design_goal $::CONFIG::ise_design_goal_default
  
  set i 0 
  for {set i 0 } { $i < $size } { incr i 1 } {
    set flag [lindex $argv $i]
    set val  [lindex $argv [ expr $i+1 ]]

    switch -- $flag {
      "-list_goals" {
        puts [ avail_design_goals ]
        exit
      }
      "-dir" {
        set dir $val
        incr i 1
      }
      "-logfile" {
        set logfile $val
        incr i 1
      }
      "-goal" {
        set design_goal $val
        incr i 1
      }
      # files
      default { 
        # extension of the file
        set ext [string tolower  [ file extension $flag ]]
        # order bellow matters
        if { ! [string compare $ext ".xco" ] } { 
            set isXCO  "1" 
        } elseif { ! [string compare $ext ".vhd" ] } { 
            set isVHDL "1" 
        } elseif { ! [string compare $ext ".ngc" ] } { 
            append ngcPath "[ file dirname [pwd]/$flag ] "
        } 
        # add files
        lappend srcs $flag; 
      }
    }
  }
  if { [ llength $srcs ] == 0 } {
    puts stderr "No files specified"
    exit 1
  }
  if { $isVHDL == 0 && $isXCO == 0 } {
    puts stderr "Don't know how to compile for these files: $srcs"
    exit 1
  }
  if { [ string compare $dir "" ] == 0 } { 
    set dir "."
    # puts stderr "Directory not specified!"
    # exit 1
  }
  if { [ string compare $logfile "" ] == 0 } {
    set logfile "$dir/ise_log.txt"
  }
  return [list $dir $logfile $isXCO $isVHDL $ngcPath $srcs $design_goal]
}

# ===================================================================== #
proc prj_reopen {} {
  puts stderr [ format "* %-40s" "Saving and reopening project"  ]
  project save
  project close
  project open proj.ise
}


# ===================================================================== #
proc ise_run {dir source_filelist compile_cmds {ngcPath "" }} {
  set saveDir [ pwd ]

  set t0 [ ::UTILS::time_mark ]
  prj_create $dir
  puts $::db_fid "ISE_PRJ_CREATE_ERROR 0" ; flush $::db_fid
  puts $::db_fid "ISE_PRJ_CREATE_CPU_TIME [ ::UTILS::time_from_now $t0 ]" ; flush $::db_fid

  set t0 [ ::UTILS::time_mark ]
  prj_addfiles $saveDir $source_filelist
  puts $::db_fid "ISE_PRJ_ADDFILES_ERROR 0" ; flush $::db_fid
  puts $::db_fid "ISE_PRJ_ADDFILES_CPU_TIME [ ::UTILS::time_from_now $t0 ]" ; flush $::db_fid

  set t0 [ ::UTILS::time_mark ]
  prj_reopen
  puts $::db_fid "ISE_PRJ_REOPEN_ERROR 0" ; flush $::db_fid
  puts $::db_fid "ISE_PRJ_REOPEN_CPU_TIME [ ::UTILS::time_from_now $t0 ]" ; flush $::db_fid

  set t0 [ ::UTILS::time_mark ]
  prj_properties $ngcPath
  puts $::db_fid "ISE_PRJ_PROPERTIES_ERROR 0" ; flush $::db_fid
  puts $::db_fid "ISE_PRJ_PROPERTIES_CPU_TIME [ ::UTILS::time_from_now $t0 ]" ; flush $::db_fid

  set t0 [ ::UTILS::time_mark ]
  prj_compile $compile_cmds
  puts $::db_fid "ISE_PRJ_COMPILE_CPU_TIME [ ::UTILS::time_from_now $t0 ]" ; flush $::db_fid

  project close
  puts $::db_fid "ISE_RUN_ERROR 0" ; flush $::db_fid
  cd "$saveDir"
}


# ===================================================================== #
# returns $compile_cmds
# gets variables from _conf.tcl
proc get_compile_cmds {isVHDL isXCO } {
  set compile_cmds ""
  if { $isVHDL } { append compile_cmds $::CONFIG::vhdl_compile_cmd }
  if { $isXCO  } { append compile_cmds $::CONFIG::xco_compile_cmd  }
  return $compile_cmds
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

# ===================================================================== #
proc avail_design_goals {} {
  set res ""
  foreach v [ UTILS::find_file $::CONFIG::ise_design_goal_dir_full/*.tcl ] {
    set fname [ file tail $v ]
    set name  [ file rootname $fname ]
    lappend res $name
  }
  return $res
}


# ===================================================================== #
proc usage {} {
  puts stderr "Responsible for hardware compilation of circuit."
  puts stderr "It can compile *vhdl circuits and coregen projects xco->ngc."
  puts stderr "Internally it steers ISE tool (it's a wrapper on Xilinx ISE)\n"
  puts stderr "Usage: $::argv0 -list_goals"
  puts stderr "\t -list_goals = lists all available design goals (policies)\n"
  puts stderr "Usage: $::argv0 -dir <directory> -logfile <file.log> -policy <file> files.{vhd,xco,ucf}"
  puts stderr "\t -dir        = directory where design will be placed"
  puts stderr "\t -logfile    = compilation logfile"
  puts stderr "\t -goal       = design goal (default: $::CONFIG::ise_design_goal_default)"
}
# ===================================================================== #
#         Main 
# ===================================================================== #
# source libs
source "[get_homedir]/$PATH_LEVEL/_conf.tcl"
source $::CONFIG::utils_file_full

# If this script was executed, and not just "source"'d, handle argv
set linked_fname [ is_linked [info script ]]
if { [ string compare $linked_fname "" ] != 0 || [string compare [info script] $argv0] == 0} { 
  if {$argc==0} {
    usage
    exit 1
  }

  # parse args and setup variables
  set args [ parse_args $argv ]
  set dir      [ lindex $args 0 ]
  set logfile  [ lindex $args 1 ]
  set isXCO    [ lindex $args 2 ]
  set isVHDL   [ lindex $args 3 ]
  set ngcPath  [ lindex $args 4 ]
  set srcs     [ lindex $args 5 ]
  set design_goal [ lindex $args 6 ]
  set compile_cmds [ get_compile_cmds $isVHDL $isXCO ]

  
  set t0 [ ::UTILS::time_mark ]
  mkdir $dir

  # open logfile
  set ::CONFIG::ise_db_api_file "$dir/$::CONFIG::ise_db_api_file"
  set_full_path ise_db_api_file
  set ::db_fid [ open $::CONFIG::ise_db_api_file_full w ]
  puts $::db_fid "ISE_CMD_OPT \"$argv\""; flush $::db_fid
  puts $::db_fid "ISE_DIR_ERROR 0" ; flush $::db_fid
  puts $::db_fid "ISE_DIR_CPU_TIME [ ::UTILS::time_from_now $t0 ]" ; flush $::db_fid

  # synthesis project
  ise_run $dir $srcs $compile_cmds $ngcPath

  # get results
  if {$isXCO ==1} {
    # we have to parse logfile to see if it was success
    set fid [ open $logfile r ]
    set data [ read $fid ]
    close $fid
    set found [ regexp {Successfully generated} $data ]
    if { $found != 1 } {
      puts stderr "* -> ERROR!"
      exit 1
    }
  } elseif {$isVHDL == 1 } {
    prj_results [ UTILS::find_file "*.twr" ]
  }
}
exit 0

# puts [ project get_processes ]
# puts [ project prop -proc Translate ]
