
# ===================================================================== #
# set detailed attributes for the ports (of vhdl compoment).
# this corresponds to exact type of the port (float, signed, unsigned)
# if it's registered or not etc.

# inputs:
#   op_ports     = list with ports
#   ns           = namespace with callbacks proc (getType isOutputReg)
# ===================================================================== #
proc ports_attributes { op_ports { ns ::ask } } {
  set result ""
  foreach p $op_ports {
    set name [ lindex $p 0 ]
    set dir  [ lindex $p 1 ]
    set type [ lindex $p 2 ]
    set size [ lindex $p 3 ]
    set val  [ lindex $p 4 ]
    set isIn 0
    set isConstant 0

    set isSign   0
    set isUnsign 0
    set isFP     0
    set exp_sz   0
    set fra_sz   0

    set isReg  0
    set isClk  0
    set isCE   0
    set isRst  0

    # find clk, clock_enable and reset signals
    if { [string compare [ string tolower $dir ] "in"] == 0 } { 
      set isIn 1 

      if {[ regexp -nocase {clk|clock} $name ]} {
        set isClk 1
        if {[ regexp -nocase {en} $name ]} {
          set isCE 1
          set isClk 0
        }
      } elseif {[ regexp -nocase {rst|reset} $name ]} {
        set isRst 1
      }

      if {[ regexp -nocase {^ce$} $name ] } {
        set isCE 1
        set isCLK 0
        set isRst 0
      }
    }

    # check if this is a constant
    if {  [ string compare $val "" ] != 0 } {
      set isConstant 1 
    }

    # for ports (which hopefully are used to transfer operands) find attributes 
    # if { $isClk==0 && $isRst==0 && $isCE==0  } \{ 
    if { $size > 1 } {
      if { [ namespace exists $ns ] == 1 } {
        set type [  ${ns}::getType $name $isIn]
        set isSign   [ lindex $type 0 ]
        set isUnsign [ lindex $type 1 ]
        set isFP     [ lindex $type 2 ]
        set exp_sz   [ lindex $type 3 ]
        set fra_sz   [ lindex $type 4 ]
        # puts "name $name"
        # puts [ format "%10s %10s %10s %10s %10s" isSign isUnsign isFP exp_sz fra_sz ] 
        # puts [ format "%10s %10s %10s %10s %10s" $isSign $isUnsign $isFP $exp_sz $fra_sz ] 
      } else { 
        puts stderr "Callback procedure '${ns}::getType' does not exists"
        exit 1
      }

    }

    if { $isIn==0 } { 
      if { [ namespace exists $ns ] == 1 } {
        set isReg [ ${ns}::isOutputReg] 
      }
    }

    if {$size != 1 } {
      set sig_name ""
      if { $isClk==1 } { set sig_name "Clock" } \
      elseif {$isCE == 1 }  { set sig_name "Clock Enable (CE)" } \
      elseif {$isRst == 1 } { set sig_name "Reset" }
      if {[string compare $sig_name "" ]} {
        puts stderr "Signal $name detected as $sig_name but size(=$size) does not match"
        exit 1
      }
    }

    set p [ lreplace $p 1 1 $isIn ]
    lappend p $isConstant $isSign $isUnsign $isFP $exp_sz $fra_sz $isReg $isClk $isCE $isRst

    lappend result $p
  }
  return $result
}


# ===================================================================== #
# print ports with detailed informations
# ===================================================================== #
proc ports_print { op_ports } {
  puts [ format \
"%15s | %4s | %30s | %4s | %4s | %4s | %4s | %10s | %4s | %4s | %4s | %4s | %4s | %4s | %4s" \
"name" "isIn" "type" "size" "clk" "ce" "rst" "val" "cons" "sign" "unsign" "fp" "exp" "fra" "reg" ]
  foreach p $op_ports {
    set name [ lindex $p 0 ]
    set isIn [ lindex $p 1 ]
    set type [ lindex $p 2 ]
    set size [ lindex $p 3 ]
    set val  [ lindex $p 4 ]
    set isConst  [ lindex $p 5 ]
    set isSign   [ lindex $p 6 ]
    set isUnsign [ lindex $p 7 ]
    set isFP     [ lindex $p 8 ]
    set exp_sz   [ lindex $p 9 ]
    set fra_sz   [ lindex $p 10 ]
    set isReg    [ lindex $p 11 ]
    set isClk    [ lindex $p 12 ]
    set isCE     [ lindex $p 13 ]
    set isRst    [ lindex $p 14 ]

  puts [ format "\
%15s | %4s | %30s | %4s | %4s | %4s | %4s | %10s | %4s | %4s | %4s | %4s | %4s | %4s | %4s" \
"$name" "$isIn" "$type" "$size" "$isClk" "$isCE" "$isRst" "$val" "$isConst" \
"$isSign" "$isUnsign" "$isFP" "$exp_sz" "$fra_sz" "$isReg" ]
  }
}

# ===================================================================== #
proc ports_get_max_size_of_inputs { ports } {
    set max 0
    foreach p $ports {
      set isIn [ lindex $p 1 ]
      if {$isIn == 1} {
        set size [ lindex $p 3 ]
        if {$size > $max} { set max $size }
      }
    }
    return $max
}
# ===================================================================== #
proc ports_correct_output_type { op_ports } {
  set input_ports  ""
  set output_ports ""
  foreach p $op_ports {
    set isIn [ lindex $p 1 ]
    if {$isIn == 1 } {
      lappend input_ports $p
    } else {
      lappend output_ports $p
    }
  }

  set new_output_ports ""
  foreach p $output_ports {
    set name [ lindex $p 0 ]
    set isIn [ lindex $p 1 ]
    set type [ lindex $p 2 ]
    set size [ lindex $p 3 ]
    set val  [ lindex $p 4 ]
    set isConst  [ lindex $p 5 ]
    set isSign   [ lindex $p 6 ]
    set isUnsign [ lindex $p 7 ]
    set isFP     [ lindex $p 8 ]
    set exp_sz   [ lindex $p 9 ]
    set fra_sz   [ lindex $p 10 ]
    set isReg    [ lindex $p 11 ]
    set isClk    [ lindex $p 12 ]
    set isCE     [ lindex $p 13 ]
    set isRst    [ lindex $p 14 ]

    # if output port does not have type
    if {$isSign == 0 && $isUnsign == 0 && $isFP == 0 } {

      # assume that type is the same as input if sizes match
      foreach in_port $input_ports {
        if {$size != [ lindex $in_port 3 ] } { continue }
        set isSign   [ lindex $in_port 6 ]
        set isUnsign [ lindex $in_port 7 ]
        set isFP     [ lindex $in_port 8 ]
        set exp_sz   [ lindex $in_port 9 ]
        set fra_sz   [ lindex $in_port 10 ]
      }
      
      # we have to assign this in this weird form
      set p [\list \
      "$name" "$isIn" "$type" \
      "$size" "$val" "$isConst" "$isSign" \
      "$isUnsign" "$isFP" "$exp_sz" "$fra_sz" \
      "$isReg" "$isClk" "$isCE" "$isRst" ]
    }
    lappend new_output_ports $p
  }

  # join results into one list
  set res ""
  foreach p $input_ports { lappend res $p }
  foreach p $new_output_ports { lappend res $p }
  return $res
}
