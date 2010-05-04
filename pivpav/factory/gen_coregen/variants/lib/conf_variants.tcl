#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh


# ===================================================================== #
# browses thru config list  and creates table with indexes for it
proc init { l_conf } {
  set idx_table ""
  set l_conf_sz [ llength $l_conf]
  for {set i 1} {$i < $l_conf_sz } {incr i 2} {
    set l_vals [ lindex $l_conf $i ]
    set sz [ llength $l_vals ]
    set row ""
    for {set j 0} {$j < $sz} {incr j 1} {
      lappend row $j
    }
    lappend idx_table $row
  }
  return $idx_table
}

# ===================================================================== #
# print table for indexes specified in v_idx list
proc print_table { v_idx } {
  upvar explore_stack::l_conf    l_conf

  set table ""

  for {set i 0} {$i < [ llength $v_idx ] } { incr i 1 } {
    set param_idx [ expr $i*2 ]
    set value_idx [ expr $param_idx + 1 ]
    # parameter name
    set param [ lindex $l_conf $param_idx ]
    # value_list for that parameter
    set l_vals [ lindex $l_conf $value_idx ]
    # get index for value
    set v_id [ lindex $v_idx $i ]
    # get value
    set value [ lindex $l_vals $v_id ]
    # collect items 
    append table [ format " \\\n\t %-30s %s" $param $value ]
  }
  return $table
}

# ===================================================================== #
# explore search space
proc explore {row} {
  upvar explore_stack::l_conf    l_conf
  upvar explore_stack::conf_sz   conf_sz
  upvar explore_stack::idx_table  idx_table
  upvar explore_stack::idx_path   idx_path
  upvar explore_stack::combination_res combination_res

  if {$row <= $conf_sz} {
      # going downwards
      set indexes [ lindex $idx_table $row ] 
      foreach id $indexes {
        set l [ llength $idx_path]
        set val "$id"
        if { $l > $row } {
          # when it's going up (from bottom to root)
          # remove tail and add current new value to the path
          set idx_path [ lreplace $idx_path $row end $val ]
        } else {
          # when its going downwards (to the bottom)
          # collect (store) path to the bottom
          lappend idx_path $val
        }
        #  !!! recursion !!!
        explore [ expr $row + 1 ]
        # going upwards
      
        # if we hit bottom get results
        if {$row == $conf_sz} {
          lappend combination_res [ print_table $idx_path]
        }
      }
  } 
  return $combination_res
}

# ===================================================================== #
# returns combination of data
proc get_combination { data } {

  namespace eval explore_stack {
#      set name [ file tail [ file rootname [info script] ]]
#      set l_conf    [ get_static_config $name ]

      uplevel { set explore_stack::l_conf $data }
      set conf_sz   [ expr [ expr [ llength $l_conf ] / 2 ] -1 ]

      set idx_table [ init $l_conf ]
      set idx_path  "1"
      set combination_res ""
  }
  set result [ explore 0 ]
  namespace delete explore_stack
  return $result

}
# ===================================================================== #

if {[ string compare [info script] $argv0] == 0 } {
      array set fp_config {
        c_optimization { Speed_Optimized Low_Latency }
        c_mult_usage   { No_Usage Medium_Usage Full_Usage Max_Usage }
      }

  set comb_conf [ get_combination [array get fp_config ] ]
  namespace delete explore_stack
  foreach c $comb_conf {
      puts $c
   }
} 
