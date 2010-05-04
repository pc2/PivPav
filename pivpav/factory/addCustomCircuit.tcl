#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

set PATH_LEVEL ".."


proc usage {} {
  puts "\nUsage: [info script]      options file.vhdl"
  puts "Options:"
  puts "  -type     name    type of the circuit"
  puts "                    arithmetic: add, sub, div, mul, sqrt, pow, log"
  puts "                    binary:     srl, srr, custom"
  puts "                    conversion: fl2int, int2fl"
  puts "                    others: cpu, controller, eth, usb"
  puts ""
  puts "  -latency cycles   latency of the combinatorial circuit"
  puts "                    it corresponds to the level of pipeline stages"
  puts "                    default: 0"
  puts "  -rate    cycles   every which cycle the inputs will be used"
  puts "                    hardware re-use operator parameter"
  puts "                    the value 0 means that the param was not setup"
  puts "                    the value 1 means that every clock cycle inputs will be read"
  puts "                    default: 0"
  puts "  -reg_output       the output of the circuit is buffered"
  puts "                    the latency of the circuit >= 1"
  puts "                    default: 0"
  puts "  -io_bufs          does it include I/O buffers (Pads)"
  puts "                    default: 0 "
  puts ""
  puts "  -size    bits     size (width) of the data bus"
  puts ""
  puts "  -fp_single        the added component is single floating precision"
  puts "                    exponenta =  8 bits"
  puts "                    fraction  =  23 bits"
  puts "                    total size = 32 bits"
  puts "  -fp_double        the added component is single floating precision"
  puts "                    exponenta =  11 bits"
  puts "                    fraction  =  52 bits"
  puts "                    total size = 64 bits"
  puts "  -fp_exp bits      custom size of the exponenta"
  puts "  -fp_fra bits      custom size of the fraction"
  puts ""
  puts "  -int_signed       all data are signed"
  puts "  -int_unsigned     all data are unsigned"
  puts ""
  puts "  -no_db            do not store results into db"
  puts "  -db_api    name   file which will be used as temporary configuration when inserting data to database"
  puts "  -db               database filename (default: ${::CONFIG::db_file_rel})"
  puts ""
}

# ===================================================================== #
proc parse_args {} {
  set ::TYPE   ""
  set ::LATENCY 0
  set ::RATE    0
  set ::REG_OUT 0
  set ::IO_BUF  0
  set ::SIZE    0
  set ::FP 0
  set ::FP_EXP 0
  set ::FP_FRA 0
  set ::INT_SIGNED 0
  set ::INT_UNSIGNED 0
  set ::NO_DB ""
  set ::VHDL_FNAME ""


  set size [ llength $::argv ]
  for {set i 0} {$i < $size} {incr i 1} {
    set flag [lindex $::argv $i ]
    set val  [lindex $::argv [ expr $i+1 ] ]

    # todo: parsing of values would be needed in here
    switch -- $flag {
      "-type"      { set ::TYPE $val ; incr i 1 }
      "-latency"   { set ::LATENCY $val ; incr i 1 }
      "-rate"      { set ::RATE $val    ; incr i 1 }
      "-reg_output" { set ::REG_OUT 1 }
      "-io_bufs"    { set ::IO_BUF 1 }
      "-size"      { set ::SIZE $val; incr i 1 }
      "-fp_single" { set ::FP 1 ; set ::FP_EXP 8; set ::FP_FRA 23  }
      "-fp_double" { set ::FP 1 ; set ::FP_EXP 11; set ::FP_FRA 52 }
      "-fp_exp"    { set ::FP 1 ; set ::FP_EXP $val; incr i 1 }
      "-fp_fra"    { set ::FP 1 ; set ::FP_FRA $val; incr i 1 }
      "-int_signed"     { set ::INT_SIGNED 1 }
      "-int_unsigned"   { set ::INT_UNSIGNED 1 }
      "-no_db"     { set ::NO_DB 1 }
      "-db_api"    { set ::CONFIG::add_cust_cir_db_api_file $val; set_full_path add_cust_cir_db_api_file; incr i }
      "-db"        { set ::CONFIG::db_file $val; set_full_path db_file; incr i }
      default { set ::VHDL_FNAME $flag  ; break }
    }
  }

  if { [ string compare $::TYPE "" ] == 0 } { 
    puts stderr "ERROR: Type name not specified"
    exit 1
  }
  if { $::LATENCY > 0  &&  $::REG_OUT == 0 } { set $::REG_OUT 1 }
  if { $::LATENCY == 0 &&  $::REG_OUT == 1 } { set $::LATENCY 1 }
  if { !  [ file exists $::::CONFIG::db_file_full ] }   { 
    puts stderr "ERROR: Database file does not exists: $::::CONFIG::db_file_rel";  
    exit 1
  }
  if { $::SIZE == -1 } {
    puts stderr "ERROR: Size of databus not specified"
    exit 1
  }

  if { $::FP == 0 && $::INT_SIGNED && $::INT_UNSIGNED } {
    puts stderr "ERROR: can't setup both options: int_signed & int_unsigned"
    exit 1
  }
  if { $::FP == 0 && $::INT_SIGNED==0  && $::INT_UNSIGNED==0 } {
    puts stderr "ERROR: you have to specify one of the  int_signed or int_unsigned options"
    exit 1
  }
  if { ! [ file exists $::VHDL_FNAME ] } { 
    puts stderr "ERROR: VHDL file does not exists: '$::VHDL_FNAME'"; 
    exit 1
  }
}

# ===================================================================== #
# Parse VHDL & get ports #
proc parse_vhdl {} {
  puts [ format "* %-40s %s" "Parsing vhdl:" $::VHDL_FNAME]
  set circuit_entity [ getComponent $::VHDL_FNAME]
  set ::circuit_entity_name  [ lindex $circuit_entity 0 ]
  set ::circuit_ports        [ lindex $circuit_entity 1 ]

  # This one bellow will try to setup attributes that can't be found in vhdl  file
  puts "* Detecting configuration of the ports for '$::circuit_entity_name'"

  # This namespace containts proc which will be used to obtain additional info about the circuit
  namespace eval ::ans { 
    proc getType { port_name isIn } {
      return [\list $::INT_SIGNED $::INT_UNSIGNED $::FP $::FP_EXP $::FP_FRA ]
    }
    proc isOutputReg {} {
      return $::REG_OUT
    }
  }
  set ::circuit_entity_ports_prop [ ports_attributes $::circuit_ports ::ans ]

  # if output signal has no type then assume that it's the same as input
  set ::circuit_entity_ports_prop [ ports_correct_output_type $::circuit_entity_ports_prop] 
  ports_print $::circuit_entity_ports_prop

  return 0
}

# ===================================================================== #
# Insert to DB

proc db_put {} {

  set db_store_file "[file rootname $::VHDL_FNAME]_${::CONFIG::gen_cg_db_api_file}"
  
  set fid [ open "$::CONFIG::add_cust_cir_db_api_file_full" w ]
  puts $fid "_DB_FNAME   ${::CONFIG::db_file_full}"

  puts $fid "\n#-- informations for circuit table --"
  puts $fid "_CF_RES_FILE      $::VHDL_FNAME"
  puts $fid "CIR_ENTITY_NAME   $::circuit_entity_name"
  puts $fid "CIR_ENTITY_PARSER_ERROR $::parser_error"

  puts $fid "\n#-- informations for ports table --"
  puts $fid "_P_INFO       $::circuit_entity_ports_prop"

  puts $fid "\n#-- informations for c_type table --"
  set ::TYPE [ string toupper $::TYPE ]
  if {[ regexp -nocase -- {(add|sub|div|mul|sqrt|pow|low)} $::TYPE {} name]} {
    puts $fid "CT_ARITHMETIC 1"
    puts $fid "CT_A_IS$name 1"
  } elseif {[ regexp -nocase -- {(srl|srr|custom)} $::TYPE {} name]} {
    puts $fid "CT_BINARY    1"
    puts $fid "CT_B_IS$name 1"
  } elseif {[ regexp -nocase -- {(fl2intl|int2fl)} $::TYPE {} name]} {
    puts $fid "CT_CONVERSION    1"
    puts $fid "CT_C_IS$name     1"
  } elseif {[ regexp -nocase -- {(cpu|controller|eth|usb)} $::TYPE {} name]} {
    puts $fid "CT_$NAME   1"
  }

  puts $fid "CT_NAME      \"$::TYPE\""

  puts $fid "\n# -- informations for c_data_type table --"
  puts $fid "CDT_SIZE    $::SIZE"

  if { $::FP == 1 } {
    set ent_size [ ports_get_max_size_of_inputs $::circuit_entity_ports_prop ] 
    set cmd_size [ expr $::FP_EXP + $::FP_FRA + 1 ] 
    if { $cmd_size != $ent_size } {
      puts stderr "WARNING: Mismatch between size specified at command line and size found in entity"
      puts stderr "WARNING: Command line = $cmd_size, entity = $ent_size"
    }

    puts $fid "CDT_ISFP    $::FP"
    puts $fid "CDT_FP_EXP  $::FP_EXP"
    puts $fid "CDT_FP_FRA  $::FP_FRA"

    if { $::FP_EXP == 8 && $::FP_FRA == 23 } {
      puts $fid "CDT_NAME fp_s"
    } elseif { $::FP_EXP == 11 && $::FP_FRA == 52 } {
      puts $fid "CDT_NAME fp_d"
    } else {
      puts $fid "CDT_NAME fp"
    }
  } else {
      puts $fid "CDT_SIZE     $::SIZE"
      puts $fid "CDT_NAME     int${::SIZE}"
      puts $fid "CDT_ISINT    1"
      puts $fid "CDT_I_SIGN   $::INT_SIGNED" 
      puts $fid "CDT_I_UNSIGN $::INT_UNSIGNED"
  }

  puts $fid "\n# -- informations for circuit_properties table --"
  puts $fid "CP_LATENCY     $::LATENCY"
  puts $fid "CP_INPUTS_RATE $::RATE"
  puts $fid "CP_HAS_PADS    $::IO_BUF"

  close $fid

  if {$::NO_DB == 1} {
    puts [ format "* %-40s" "skipped" ]
    return
  }

  puts "* Storing into db:  $::CONFIG::db_file_rel circuit:\
  $::VHDL_FNAME, with entity name: $::circuit_entity_name"

  ::INSERT_DB::create_parser
  ::PARSER::parse $::CONFIG::add_cust_cir_db_api_file
  set rowid [ ::INSERT_DB::insert_db ]
  puts "* Success, circuit rowid=$rowid"
#  file delete $::CONFIG::add_cust_cir_db_api_file_full

#  puts "* ROWID = $op_id"
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
# Main
# ===================================================================== #
source "[get_homedir]/$PATH_LEVEL/_conf.tcl"
source $::CONFIG::utils_file_full
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
  parse_args

  puts [ format "\n%s\n%s\n%s" "$::CONFIG::comment_line" "# Parsing component" "$::CONFIG::comment_line" ]
  set ::parser_error [ parse_vhdl ]

  puts [ format "\n%s\n%s\n%s" "$::CONFIG::comment_line" "# Storing to database" "$::CONFIG::comment_line" ]
  db_put
}
