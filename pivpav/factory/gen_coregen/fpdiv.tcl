#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

# ===================================================================== #
# This is template for operators. With usage of it they can develop
# their own *.xco file.
# This file is linked -> operator_name.tcl
# Usage: ./operator_name.tcl parameter value
# ===================================================================== #


set path_dir "[file dirname [info script]]"
source "$path_dir/lib/xco_parser.tcl"
source "$path_dir/lib/xco_writer.tcl"
source "$path_dir/lib/xco_constr.tcl"
source "$path_dir/lib/xco_maps.tcl"

# ================================== #
# find which file
# ================================== #
set fname [ file rootname [ file tail [ info script ] ] ]
regsub -nocase {\.\/} $fname {} fname

# ================================== #
# read customized xco api for component
# ================================== #
source "$path_dir/xco_maps/${fname}.tcl"

# ================================== #
# parse configuration for component
# ================================== #
::XCO_PARSER::parse "$path_dir/xco_files/${fname}.xco"

# ================================== #
# show some values
# ================================== #
# puts [ isSigned a ]
# puts [ xco_get name ]
# puts [ xco_get sync]
# puts [ xco_get latency ] 
# puts [ xco_get output_size ]

# ================================== #
# reconfgiure some parameters
# change params throug general api
# ================================== #
# xco_set   name "mul"
# xco_set   port_a_size 32
# xco_set   port_a_sign unsigned
# xco_set   port_b_size 32
# xco_set   port_b_sign unsigned
# xco_set   output_size 32
# xco_set   pipeline 0
# xco_set   clock_enable false

proc usage {} {
  set op $::fname
  puts "(Modify and) show xco configuration for '$op' operator"
  puts "usage: [info script]   <-list_params>  <param value>"
  puts "\t -list_params  = prints all available parameters"
  puts "\t param         = pattern which will be used to find xco variable"
  puts "\t value         = this value will be assigned to parameter"
}

proc show_params {} {
  puts "Predefined mappings:"
  set body [ info body ::XCO_MAP::xco_get ]
  set var_list [\list ]
  foreach f [ split $body \n ] {
    if {[ regexp {^\s*(\S+)\s*\{.*CSET::_(\S+)} $f { } name map ]} {
      if {[ string compare $name "default" ] == 0 } { continue }
      # puts [ format "      %-15s -> %-25s (def value: %s)" "$name" $map [xco_get $map ]]
      puts [ format "      %-25s -> %-25s" "$name" $map]
      lappend var_list $map
    }
  }

  puts "All variables:"
  foreach v [ info vars CSET::* ]  {
    regexp {::CSET::_(\S+)} $v {} name
    set x " "
    if {[lsearch $var_list $name] != -1 } {
      set x "*"
    }
    puts [ format "    %s %-25s = %s" $x $name "[ set $v ]" ]
  }
  # puts "    *  = mapping exists for variable"
}
# ================================== #
# parse arguments
# ================================== #
if {$argc != 0 } {
  set first_param [ lindex $argv 0 ]
  switch -regexp -- $first_param {
    "-list_params" { 
        show_params
        exit
      }
    "-help|-h" {
        usage
        exit
     }
  }

  # if this script is executed from other tcl script, then
  # all params are available at argv1. We have to split it.
  set params ""
  for {set i 0} { $i < $argc} { incr i 1} {
    set v [ lindex $argv $i ]
    foreach v [ split $v ] {
      lappend params $v
    }
  }

  set params_size [ llength $params ]
  if { [ expr $params_size%2] } {
    puts "Wrong number of parameters"
    exit 
  } 


  # setup xco params
  for {set i 0} { $i < $params_size} { incr i 2} {
    set param [ lindex $params $i ]
    set value [ lindex $params [ expr $i+1 ] ]
    ::XCO_MAP::xco_set $param $value 
  }
}


# write down configuration
xco_write
