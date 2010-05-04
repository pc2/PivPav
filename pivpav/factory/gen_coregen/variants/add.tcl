#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

set PATH_LEVEL "../.."

# ===================================================================== #
# return "" if this is script is not linked
# return "linked fname" otherwise
proc get_link_from {fname} {
  set rc [ catch {set link [ file link $fname ]} ]
  if {$rc == 0} {
    return $link
  }
  return ""
}

proc get_homedir {} {
  upvar #0 argv0 script_name
  set dir [ file dirname $script_name ] 

  # when linked
  set fname [ get_link_from $script_name ] 
  if { [ string compare $fname "" ] != 0 } {
    set script_name "$dir/$fname"
  }
  # find homedir of the script
  set HOMEDIR [ file dirname $script_name ]
  return $HOMEDIR
}

# ===================================================================== #
proc range { val } {
  set res ""
  foreach v $val {
    if {[ regexp {(\d+)-(\d+)} $v {} min max ] }  {
      for {set i $min } {$i <= $max} {incr i 1 } {
        lappend res $i
      }
    } elseif { [regexp {(\d+),(\d+)} $v {} a b ] } {
      lappend res $a
      lappend res $b
    } else {
      lappend res $v
    }
  }
  return $res
}

# ===================================================================== #
proc get_add_params {} {
  set res ""
  foreach type $::TYPE {
    foreach imp $::IMPLEMENTATION {
      set varname_width [ format "::WIDTH_%s" $imp ]
      foreach w [set $varname_width ] {
        if {[ regexp {Fabric} $imp ]} {
          set lat_range [ range 0-$w ]
        } else {
          set lat_range [ range $::LATENCY_DSP48 ]
        }
          foreach r [ range $lat_range ] {
            set msg ""
            if {$r == 0} { set msg "c_en false" }
            lappend res "a_type $type b_type $type implementation $imp a_width\
            $w b_width $w out_width $w latency $r $msg"
          }
      }
    }
  }
  return $res
}

proc get_sqrt_params {} {
  set res ""
  foreach mode $::PIPEMODE {
    foreach w $::WIDTH {
      set o_sz [ expr [ expr $w + 2 ] / 2 ]
      lappend res "pipelining_mode $mode input_width $w output_width $o_sz"
    }
  }
  return $res
}

proc get_mul_params {} {
  set res ""
  foreach type $::TYPE {
    foreach constr $::CONSTR {
      foreach op $::OPT {
        set varname [ format "::WIDTH_%s" $type ]
        foreach w [ set $varname ] {
          foreach pipe $::PIPESTAGES {
            foreach l [ range $pipe ] {
              set row    "portatype $type "
              append row "portbtype $type "
              append row "optgoal $op "
              append row "multiplier_construction $constr "
              append row "pipestages $l "
              append row "portawidth $w "
              append row "portbwidth $w "
              if {$w == 0} { append row "clockenable false" }
              lappend res  $row
            }
          }
        }
      }
    }
  }
  return $res
}

proc get_div_latency { sign frac clk_div m_sz f_sz} {
  set res $m_sz

  if {[ regexp -nocase -- {Fractional} $frac ]} { incr res $f_sz }

  set base 4
  if {[ regexp -nocase -- {Unsigned} $sign ] } { set base 2 }
  incr res $base

  if {$clk_div > 1} { incr res 1 }
  return $res 
}

# Support only 1 algorithm
proc get_div_params {} {
  set res ""
  foreach alg $::ALGO {
    set varname_sz  [ format "::WIDTH_%s"     $alg ]
    set varname_ty  [ format "::TYPE_%s"      $alg ]
    set varname_clk [ format "::CLK_OP_%s"    $alg ]
    set varname_fra [ format "::WIDTH_%s_FRA" $alg ]

    foreach mode $::MODE {
      foreach clk [ set $varname_clk ] {
        foreach ty [ set $varname_ty ] {
          foreach w [ range [ set $varname_sz ]] {
            foreach fra [ range [ set $varname_fra ]] {
              set row    "algorithm_type $alg "
              append row "clocks_per_division $clk "
              append row "operand_sign $ty "
              append row "dividend_and_quotient_width $w "
              append row "divisor_width $w "
              append row "fractional_width $fra "
              set lat [get_div_latency $ty $mode $clk $w $fra ]
              append row "latency $lat "
              if {$lat == 0 } { append row "ce false" }
              append row "remainder_type $mode "
              append row "latency_configuration Manual "

              lappend res $row
            }
          }
        }
      }
    }
  }
  return $res
}

proc get_params { name } {
  switch -regexp -- $name {
    "add|sub" { add_constrains  ; return [ get_add_params  ] }
    "sqrt"    { sqrt_constrains ; return [ get_sqrt_params ] } 
    "mul"     { mul_constrains  ; return [ get_mul_params  ] } 
    "div"     { div_constrains  ; return [ get_div_params  ] }
  }
}

# ===================================================================== #
proc add_constrains {} {
  # defaults
  set ::TYPE  { Signed Unsigned }
  set ::IMPLEMENTATION { Fabric DSP48 }
  set ::WIDTH_Fabric { 2-256 } 
  set ::WIDTH_DSP48_A { 2-48 } 
  set ::WIDTH_DSP48_B { 2-36 } 
  # set ::LATENCY_Fabric { 0-258 }
  set ::LATENCY_DSP48 { 0-2 }

  # our modified settings
  set ::WIDTH_Fabric $::MY_SIZE
  set ::WIDTH_DSP48  $::MY_SIZE
  # when LATENCY_DSP48 = 2 -> inputs registered (do not allow)
  set ::LATENCY_DSP48 { 0,1 }
  #  ::LATENCY_Fabrit { 0-output_width }
}

proc sqrt_constrains {} {
  # defaults
  # no control over latency with this settings
  set ::PIPEMODE { Maximum Optimal No_Pipelining }
  set ::WIDTH    { 8-48 }

  # our modified settings
  set ::PIPEMODE { No_Pipelining }
  set ::WIDTH    $::MY_SIZE
}

proc mul_constrains {} {
  # defaults
  set ::WIDTH_Unsigned  { 1-64 }
  set ::WIDTH_Signed    { 2-64 }
  set ::TYPE     { Signed Unsigned }
  set ::CONSTR   { Use_LUTs Use_Mults }
  set ::OPT      { Speed Area }
  set ::PIPESTAGES { 0-30 }

  # our modified settings
  set ::WIDTH_Unsigned $::MY_SIZE
  set ::WIDTH_Signed   $::MY_SIZE
}
proc div_constrains {} {
  # defaults
  set ::ALGO { Radix2 High_Radix }
  set ::MODE             { Fractional Remainder }
  set ::WIDTH_Radix2_FRA { 2-32 }
  set ::WIDTH_Radix2     { 2-32 }
  set ::TYPE_Radix2      { Unsigned Signed  }
  set ::CLK_OP_Radix2    { 1 2 4 8 }

  set ::WIDTH_High_Radix  { 4-54 }
  # set ::WIDTH_High_Radix_FRA { 2-32 }
  set ::TYPE_High_Radix   { Signed  }
  set ::CLK_OP_High_Radix { 1 }

  # our modified settings
  set ::ALGO             { Radix2 }
  set ::MODE             { Fractional }
  set ::WIDTH_Radix2      $::MY_SIZE

}
# ===================================================================== #
proc main {} {
  set fname [ file tail [info script ] ]
  set fname_root [ file rootname $fname ]

  puts "main"
  foreach c [ get_params "$fname_root" ] {
        puts "$fname_root $c"
  }
}

# ===================================================================== #
#         Main 
# ===================================================================== #
#set MY_SIZE { 32 }
set MY_SIZE { 64 }

set homedir   "[get_homedir]"
set rootlevel "$homedir/$PATH_LEVEL"

set linked_fname [ get_link_from [ info script ]]

  main
  exit
if { [ string compare $linked_fname "" ] != 0 } {
  main
} else {
  foreach f [ glob $homedir/*.tcl ] {
    if {[ string compare $f [info script ]] == 0 } { continue }
    if {[ regexp {^./fp} $f ] } { continue }
    puts [ exec xtclsh $f ]
  }
}
