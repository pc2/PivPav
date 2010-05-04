#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

set PATH_LEVEL ".."


# ===================================================================== #
# Responsible for generation of the components.
# ===================================================================== #

proc avail_comps {} {
  set path "${::CONFIG::gen_cg_dir_full}/*.tcl"
  foreach v [ ::UTILS::find_file $path ] {
    set fname [ file tail $v ]
    # skip generator
    set opfile [ file tail $::CONFIG::gen_cg_op_file ]
    if { [ string compare $fname $opfile ] == 0 } { continue; }
    set name  [ file rootname $fname ]
    if {[regexp {^\s*fp} $name {} ] } {
      lappend fp_comp_list $name
    } else {
      lappend int_comp_list $name
    }
  }
  set res    "* Integer operators:  [lsort $int_comp_list]\n"
  append res "* Floating operators: [lsort $fp_comp_list]"
  return $res
}

proc usage {} {
  set comp_list [ avail_comps ]

  puts "[info script]   <-list_ops>" 
  puts "  -list_circuits   list all available circuits"
  puts ""
  puts "[info script]    <-log> <-dir> <-db> <-no_compile> <-no_db> <-list_params> circuit_name <param value>"
  puts "  -log             duplicate stdout & stderr to '${::CONFIG::gen_cg_stdout_dup_file}' and '${::CONFIG::gen_cg_stderr_dup_file}' files"
  puts "  -dir x           output directory (under ${::CONFIG::gen_cg_compile_dir_rel} path)"
  puts "                   default x = circuitname"
  puts "  -db              database filename"
  puts "  -no_compile      do not compile circuit, use one from default compilation directory"
  puts "  -no_db           do not store results into db"
  puts "  -list_params     list parameters of the given circuit"
  puts "   circuits:\n\t[ join [ split $comp_list \n ] \n\t ] "
  puts "  <param value>    setup parameters"
  puts ""
}

# ===================================================================== #
proc parse_args {} {
  # initialization
  set ::no_compile 0
  set ::no_db 0
  set ::xco_component ""
  set ::xco_params ""
  set ::list_params_flag 0
  set ::dir_flag 0
  set ::dir_flag_val ""
  set ::db_flag 0
  set ::db_flag_val ""
  set ::log_flag 0

  set size [ llength $::argv ]
  for {set i 0} {$i < $size} {incr i 1} {
    set flag [lindex $::argv $i ]
    set val  [lindex $::argv [ expr $i+1 ] ]

    switch -- $flag {
      "-log" {
        set ::log_flag 1
      }
      "-list_circuits" {
        puts [ avail_comps ] 
        exit
      }
      "-list_params" {
        set ::list_params_flag 1
      }
      "-no_compile" {
        set ::no_compile 1
      }
      "-no_db" {
        set ::no_db 1
      }
      "-dir" {
        set ::dir_flag 1
        set ::dir_flag_val $val
        incr i 1
      }
      "-db" {
        set ::db_flag 1
        set ::CONFIG::db_file $val
        set_full_path db_file
        incr i 1
      }
      default {
          set ::xco_component [ lindex $::argv $i]
          incr i
          set ::xco_params    [ lrange $::argv $i end ]
          break;
      }
    }
  }

  if {[string compare $::xco_component ""] == 0} {
    puts stderr "Component not specified.\n"
    usage
    exit
  }

  if {[lsearch [avail_comps] $::xco_component] == -1 } {
    puts stderr "Operator name does not match to any of these:\n [avail_comps]"
    exit
  }

  # these are constant values
  set ::comment    "${::CONFIG::comment_line}"

  # these depend on circuit name
  set ::xco_gen_rel      "${::CONFIG::gen_cg_dir_rel}/${::xco_component}.tcl"
  set ::xco_gen_full     "${::CONFIG::gen_cg_dir_full}/${::xco_component}.tcl"
  set ::xco_mapper_rel   "${::CONFIG::gen_cg_maps_dir_rel}/${::xco_component}.tcl"
  set ::xco_mapper_full  "${::CONFIG::gen_cg_maps_dir_full}/${::xco_component}.tcl"
  if { $::dir_flag == 0 } {
    set ::work_dir_rel     "${::CONFIG::gen_cg_compile_dir_rel}/${::xco_component}"
    set ::work_dir_full    "${::CONFIG::gen_cg_compile_dir_full}/${::xco_component}"
  } else {
    set ::work_dir_rel     "${::CONFIG::gen_cg_compile_dir_rel}/${::dir_flag_val}"
    set ::work_dir_full "${::CONFIG::gen_cg_compile_dir_full}/${::dir_flag_val}"
  }

  set ::gen_dir_rel        "$::work_dir_rel/${CONFIG::gen_cg_work_dir}"
  set ::gen_dir_full       "$::work_dir_full/${CONFIG::gen_cg_work_dir}"
  set ::gen_vhdl_file_rel  "$::work_dir_rel/${CONFIG::gen_cg_work_dir}/${::xco_component}.vhdl"
  set ::gen_vhdl_file_full "$::work_dir_full/${CONFIG::gen_cg_work_dir}/${::xco_component}.vhdl"
  set ::gen_ngc_file_rel   "$::work_dir_rel/${CONFIG::gen_cg_work_dir}/${::xco_component}.ngc"
  set ::gen_ngc_file_full  "$::work_dir_full/${CONFIG::gen_cg_work_dir}/${::xco_component}.ngc"
  set ::xco_fname_full     "$::work_dir_full/${::xco_component}.xco"
  set ::xco_fname_rel      "$::work_dir_rel/${::xco_component}.xco"
  set ::db_fname_rel       "$::work_dir_rel/${::CONFIG::gen_cg_db_api_file}"
  set ::db_api_file_full      "$::work_dir_full/${::CONFIG::gen_cg_db_api_file}"
  set ::xst_log_full       "$::work_dir_full/${::xco_component}_xst.log"
}

# ===================================================================== #
proc mkdir {} {
  if {$::no_compile == 1 } {
      puts [ format "* %-40s" "skipped" ]
  } else {
    if {[file isdirectory $::work_dir_full]} {
      puts [ format "* %-40s %s" "Removing directory" $::work_dir_rel ]
      file delete -force $::work_dir_full
    }
    puts [ format "* %-40s %s" "Creating directory" $::work_dir_rel ]
    file mkdir $::work_dir_full
    file mkdir $::gen_dir_full
  }
}

# ===================================================================== #
# Create & Parse XCO file   # 
proc xco_parsers {} {
    puts [ format "* %-40s %s" "Load parser:" ${::CONFIG::gen_cg_xco_parser_file_rel} ]
    source "${::CONFIG::gen_cg_xco_parser_file_full}"

    puts [ format "* %-40s %s" "Load mapper:" $::xco_mapper_rel ]
    source $::xco_mapper_full

  if {$::no_compile == 0 } {
    puts [ format "* %-40s %s" "Generate with:" $::xco_gen_rel ]
    catch { exec xtclsh $::xco_gen_full $::xco_params > $::xco_fname_full } 
  } else {
    puts [ format "* %-40s %s" "no compilation = Reading configuration:" $::xco_fname_rel ]
    set fid [ open $::xco_fname_full r ]
    set xco_data [ read $fid ]
    close $fid
    if {[file exists "$::work_dir_full/${::CONFIG::gen_cg_time_file}" ]} {
      set fid [ open "$::work_dir_full/${::CONFIG::gen_cg_time_file}" ]
      set ::t_end [ string trimright [ read $fid ] ]
    } else {
      set ::t_end -1
    }
    close $fid
  }

  puts [ format "* %-40s" "Parse xco configuration" ]
  ::XCO_PARSER::parse $::xco_fname_full
  # puts [ xco_get port_a_size ]
}

# ===================================================================== #
# Coregen generate #
# ise compilation process has side-effects (not our fault - blame xilinx)
# to get rid of it we run it as a seperate process

proc generate {} {
  if {$::no_compile == 1 } {
      puts [ format "* %-40s" "skipped" ]
      return 0
  }

  # puts [ format "* %-40s" "Timer start." ]
  set t0 [ ::UTILS::time_mark ]

  set savePWD [ pwd ]
  cd $::gen_dir_full

  # set data [ exec coregen -b $xco_file ]
  # puts $data

  set coregen [ exec which coregen ] 
  if {[string compare $coregen "" ] == 0 } { 
    puts stderr "coregen not found" 
    exit 1 
  }
  if {[ file exists $::xco_fname_full ] == 0 } { 
    puts stderr "xco_file not found"
    puts stderr "pwd = [pwd]"
    puts stderr "xco_file = $::xco_fname_full"
    exit 1
  }
  set cmd "$coregen -b $::xco_fname_full"
  set fid [ open "|$cmd" r ]
  fconfigure $fid -blocking false 
  fconfigure $fid -buffering none
  fconfigure $fid -buffersize 20
  set isError 1
  while { ![eof $fid]} { 
    set data [ read $fid ]
    if {[string compare $data "" ] == 0 } { continue }
    # puts -nonewline  "# $data"
    if {[regexp {Finished moving files to output directory} $data]} {
      set isError 0
    }
    if {[regexp {Successfully generated} $data]} {
      set isError 0
    }
  }
  cd $savePWD

  if {$isError == 1 } {
    puts [ format "* %-40s" "-> Compilation Aborted see logfile: $::xst_log_full" ]
  }
  close $fid

  set ::t_end [ ::UTILS::time_from_now $t0 ]
  puts [ format "* %-40s %s sec" "Elapsed time: " "$::t_end"]
  set fid [ open "$::work_dir_full/${::CONFIG::gen_cg_time_file}" w ]
  puts $fid $::t_end
  close $fid

  return $isError
}

# ===================================================================== #
# Parse VHDL & get ports #
proc parse_vhdl {} {
  set vhdlfiles [ ::UTILS::find_file "$::gen_dir_rel/*.vhd" ]
  if { [ string compare $vhdlfiles "" ] == 0 } {
    puts [ format "* %-40s %s" "Parsing vhdl:" "no files found" ]
    # return failure
    return 1
  }
  puts [ format "* %-40s %s" "Parsing vhdl:" $vhdlfiles ]
  set circuit_entity [ getComponent $vhdlfiles ]
  set ::circuit_entity_name  [ lindex $circuit_entity 0 ]
  set ::circuit_ports        [ lindex $circuit_entity 1 ]

  ######################################################
  # Set isRegistered and isSigned attributes for ports #
  # this infos are not available in vhdl only in xco   #
  ######################################################
  puts "* Detecting configuration of the ports "
  set ::circuit_entity_ports_prop [ ports_attributes $::circuit_ports ::XCO_MAP ]

  # if output signal has no type then assume that it's the same as input
  set ::circuit_entity_ports_prop [ ports_correct_output_type $::circuit_entity_ports_prop] 
  ports_print $::circuit_entity_ports_prop

  return 0
}

# ===================================================================== #
# Insert to DB    #

proc db_put {} {
  puts "* Storing into db component: $CSET::_component_name"
#  set rowid [ db_insert_operator_with_ports $::db_fname $::t_end
#  $::gen_dir_full $::xco_fname $::circuit_entity_ports_prop]

  set fid [ open "${::db_api_file_full}" w ]
  puts $fid "_DB_FNAME   ${::CONFIG::db_file_full}"

  puts $fid "\n# -- informations for device table --"
  puts $fid "D_DEVICE     \"$SET::_device\""
  puts $fid "D_FAMILY     \"$SET::_devicefamily\""
  puts $fid "D_PACKAGE    \"$SET::_package\""
  puts $fid "D_SPEEDGRADE \"$SET::_speedgrade\""


  puts $fid "\n#-- informations for generator table --"
  puts $fid "_GF_KEY_PRJ  $::work_dir_full"
  puts $fid "G_NAME       \"coregen_v11.1\""
  puts $fid "G_CMD_OPT    \"$::argv\""
  puts $fid "G_IS_ERROR   $::generator_error"
  puts $fid "G_CPU_TIME   $::t_end"

  puts $fid "\n#-- informations for circuit table --"
  puts $fid "_CF_RES_FILE      $::gen_ngc_file_full"
  puts $fid "CIR_ENTITY_NAME \"[ ::XCO_MAP::xco_get component_name ]\""
  puts $fid "CIR_ENTITY_PARSER_ERROR $::parser_error"

  puts $fid "\n#-- informations for ports table --"
  puts $fid "_P_INFO       $::circuit_entity_ports_prop"

  # THIS SECTION CAN BE REWRITTEN WITH XCO_MAP::getType ...
  # ALLOWING TO OBTAIN PROPERTIES OF THE CIRCUIT IN AUTOMATIC WAY

  puts $fid "\n#-- informations for c_type table --"
  set operation [ ::XCO_MAP::xco_get operation ]
  puts $fid "CT_NAME   \"$operation\"" 
  puts $fid "CT_GROUP_NAME      \"$::SELECT::_SELECT\""
  if {[ regexp -nocase -- {(add|sub|div|mul|sqrt|pow|low)} $operation {} name]} {
    set name [ string toupper $name ]
    puts $fid "CT_ARITHMETIC 1"
    puts $fid "CT_A_IS$name 1"
  } elseif {[ regexp -nocase -- {(srl|srr)} $operation {} name]} {
    set name [ string toupper $name ]
    puts $fid "CT_BINARY    1"
    puts $fid "CT_B_IS$name 1"
  } elseif {[ regexp -nocase -- {(fl2intl|int2fl)} $operation {} name]} {
    set name [ string toupper $name ]
    puts $fid "CT_CONVERSION    1"
    puts $fid "CT_C_IS$name     1"
  } elseif {[ regexp -nocase -- {(cpu|controller|eth|usb)} $operation {} name]} {
    set name [ string toupper $name ]
    puts $fid "CT_$NAME   1"
  }

  # THIS SECTION CAN BE REWRITTEN WITH XCO_MAP::getType ...
  # ALLOWING TO OBTAIN PROPERTIES OF THE CIRCUIT IN AUTOMATIC WAY

  puts $fid "\n# -- informations for c_data_type table --"
  set size [ ::XCO_MAP::xco_get size ]
  puts $fid "CDT_SIZE   $size"
  if { [ regexp {Floating-point} $::SELECT::_SELECT ] } { 
    puts $fid "CDT_ISFP  1"
    set exp_sz [ ::XCO_MAP::xco_get exponent ]
    set fra_sz [ ::XCO_MAP::xco_get fraction ]
    puts $fid "CDT_FP_EXP  $exp_sz"
    puts $fid "CDT_FP_FRA  $fra_sz"
    if { $exp_sz == 8 && $fra_sz == 24 } {
      puts $fid "CDT_NAME fp_s"
    } elseif { $exp_sz == 11 && $fra_sz == 53 } {
      puts $fid "CDT_NAME fp_d"
    } else {
      puts $fid "CDT_NAME fp"
    }
  } else { 
      puts $fid "CDT_NAME  int${size}"
      puts $fid "CDT_ISINT 1"
      if { [ regexp -nocase {sign} [ ::XCO_MAP::xco_get port_a_sign ] ] } {
        puts $fid "CDT_I_SIGN 1"
      } else {
        puts $fid "CDT_I_UNSIGN 1"
      }
  }


  puts $fid "\n# -- informations for circuit_properties table --"
  puts $fid "CP_LATENCY     [ ::XCO_MAP::xco_get latency ]"
  puts $fid "CP_INPUTS_RATE [ ::XCO_MAP::xco_get inputs_rate]"
  set pads 0 ; if {[ regexp -nocase {True} $::SET::_addpads ] == 1 } { set pads 1 }
  puts $fid "CP_HAS_PADS $pads"

  # puts $fid "\n# -- informations for file table --"
  # puts $fid "F_HAS_XCO    1"
  # puts $fid "F_HAS_VHDL   1"
  # if {$::log_flag == 1 } {
  #   puts $fid "F_IS_STDOUT 1"
  #   puts $fid "F_IS_STDERR 1"
  # }
  close $fid
  exec sync

   if {$::no_db == 1} {
    puts [ format "* %-40s" "skipped" ]
    return
  }

 
  ::INSERT_DB::create_parser
  ::PARSER::parse $::db_api_file_full
  set ::no_files_flag 0
  set rowid [ ::INSERT_DB::insert_db ]
  puts "* Success, circuit rowid=$rowid"
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

# establishes the home directory from which the script is running
# takes into the account that the script can be linked
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
# Main
# ===================================================================== #
source "[get_homedir]/$PATH_LEVEL/_conf.tcl"
set DEBUG $::CONFIG::gen_debug
source $::CONFIG::utils_file_full
source $::CONFIG::gen_cg_xco_parser_file_full
source $::CONFIG::gen_cg_xco_maps_file_full
source $::CONFIG::vhdl_parse_api_file_full
source $::CONFIG::vhdl_ports_api_file_full
source $::CONFIG::db_insert_cir_file_full



# If this script was executed, and not just "source"'d, handle argv
set linked_fname [ is_linked [info script ]]
if { [ string compare $linked_fname "" ] != 0 || [string compare [info script] $argv0] == 0} { 
  if {$argc == 0} { 
    usage
    exit
  }
  # initialize and setup variables
  parse_args

  if {$list_params_flag == 1 } {
    puts [  exec xtclsh $::xco_gen -list_params  ]
    exit 
  }

  if {$::log_flag == 1} { 
    ::UTILS::redirect_stdout_stderr  ${::CONFIG::gen_cg_stdout_dup_file} ${::CONFIG::gen_cg_stderr_dup_file}
  }

  puts [ format "%s\n%s\n%s" "$::comment" "# Project directory" "$::comment" ]
  mkdir

  puts [ format "\n%s\n%s\n%s" "$comment" "# XCO configuration" "$comment" ]
  xco_parsers

  puts [ format "\n%s\n%s\n%s" "$comment" "# Generating circuit" "$comment" ]
  set generator_error [ generate ]

  puts [ format "\n%s\n%s\n%s" "$comment" "# Parsing the top entity of the circuit" "$comment" ]
  set parser_error [ parse_vhdl ] 

  puts [ format "\n%s\n%s\n%s" "$comment" "# Storing to database" "$comment" ]
  db_put

  # at the end move log files
  if {$::log_flag == 1 } {
    file rename -force ${::CONFIG::gen_cg_stdout_dup_file} $::work_dir_full
    file rename -force ${::CONFIG::gen_cg_stderr_dup_file} $::work_dir_full
  }
}
