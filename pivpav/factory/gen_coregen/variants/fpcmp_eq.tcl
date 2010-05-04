#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

# TODO: add $config from command line

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
proc get_size {type fra exp} {
  set row ""
  append row "a_precision_type $type "
  append row "result_precision_type $type "
  append row "c_a_exponent_width $exp "
  append row "c_result_exponent_width $exp "
  append row "c_a_fraction_width $fra "
  append row "c_result_fraction_width $fra "
  return $row
}

proc get_rate_and_latency {rate latency bool_max_lat } {
  set row ""
  append row "c_rate $rate " 
  append row "c_latency $latency "
  append row "maximum_latency $bool_max_lat " 
  return $row
}

proc gen_rate_and_latency  { max_rate max_lat } {
  set res ""

  for {set l 0 } { $l <= $max_lat } { incr l 1 } {
    for {set r 1} { $r <= $max_rate } {incr r 1 } {
        # Constrain: c_rate <= c_latency (otherwise it does not make sense)
        if {$r > $l} { continue }
        if {$l == $max_lat } { set bool_max_lat "true" } else { set bool_max_lat "false" }
        lappend res [ get_rate_and_latency $r $l $bool_max_lat ] 
    }
  }
  return $res
}

# This table corresponds only to Virtex-4 family series.
proc get_max_latency_fpmul { c_fraction_width c_optimization } {
  set fra $c_fraction_width
  switch $c_optimization {
    "No_Usage"     { 
      if {$fra == 4 || $fra == 5}    { return 5 }
      if {$fra >= 6 && $fra <= 11 }  { return 6 }
      if {$fra >= 12 && $fra <= 13 } { return 7 }
      if {$fra >= 24 && $fra <= 47 } { return 8 }
      if {$fra >= 48 && $fra <= 64 } { return 9 }
    }
    "Full_Usage" {
      if {$fra >= 4  && $fra == 17}  { return 6  }
      if {$fra >= 18 && $fra <= 34 } { return 10 }
      if {$fra >= 35 && $fra <= 51 } { return 15 }
      if {$fra >= 52 && $fra <= 64 } { return 22 }
    }
    "Max_Usage"  {
      if {$fra >= 4  && $fra == 17}  { return 8  }
      if {$fra >= 18 && $fra <= 34 } { return 11 }
      if {$fra >= 35 && $fra <= 51 } { return 16 }
      if {$fra >= 52 && $fra <= 64 } { return 23 }
    }
  }
  puts stderr "Couldn't find maximum latency for operator fpmul, fraction size '$fra' and optimization '$c_optimization'"
  exit 1
}



# 3 & 4th params:
# * are present then 1 & 2nd are skipped
# * they specify upper limit based on $fra
proc get_template { max_c_rate max_c_latency {incr_rate {0}} {incr_latency {0}} } {
  set res ""
  foreach {type fra exp} $::WIDTH  {
    if {$incr_rate != 0}     { set max_c_rate    [ expr $fra + $incr_rate ]} 
    if {$incr_latency != 0 } {set max_c_latency [ expr $fra + $incr_latency ]}
    set size_params [ get_size $type $fra $exp ]
    foreach c [ gen_rate_and_latency $max_c_rate $max_c_latency ] {
      append c $size_params
      lappend res $c
    }
  }
  return $res
}

proc get_fpmul_params { } {
  set res ""

  set t "c_mult_usage Medium_Usage "
  foreach {type fra exp} $::WIDTH {
    set size [ get_size $type $fra $exp ] 
    foreach opt {Speed_Optimized Low_Latency} {
       set o "c_optimization $opt "
       foreach {c_mult_usage} { No_Usage Full_Usage Max_Usage } {
          set max_latency [ get_max_latency_fpmul $fra $c_mult_usage ]
          foreach c [ gen_rate_and_latency 1 $max_latency ] {
            append c "c_mult_usage $c_mult_usage "
            lappend res "$size$o$c"
          }
       }
        # this are single entries
        if {[ regexp {Single} $type ]} {
          set m [ get_rate_and_latency 1 9 "true" ]
        } elseif {[ regexp {Double} $type] } {
          set m [ get_rate_and_latency 1 17 "true" ]
        } else {
          continue
        }
        append m $t
        lappend res "$size$o$m"
    }
  }
  return $res
}

proc get_fpaddsub_params {} {
  set res ""
  foreach {type fra exp} $::WIDTH {
  set size [ get_size $type $fra $exp ]
    foreach opt {Speed_Optimized  Low_Latency} {
      set o "c_optimization $opt "
      if {[regexp {Single} $type]} {
        set w "c_mult_usage No_Usage "
        foreach t  [ gen_rate_and_latency 1 13 ] { lappend res "$size$o$w$t" } 
        set w "c_mult_usage Full_Usage "
        foreach t [ gen_rate_and_latency 1 16 ] { lappend res "$size$o$w$t" }
      } elseif {[regexp {Double} $type]} {
        set w "c_mult_usage No_Usage "
        foreach t [ gen_rate_and_latency 1 14 ] { lappend res "$size$o$w$t" }
        set w "c_mult_usage Full_Usage "
        foreach t [ gen_rate_and_latency 1 15 ] { lappend res "$size$o$w$t" }
      }
    }
  }
  return $res
}


# returns an list with combination of parameters for given component
proc get_params { name } {
  switch -regexp -- $name {
    "fpdiv"  { return [ get_template 0 0 2 4 ] }
    "fpsqrt" { return [ get_template 0 0 1 4 ] }
    "fpcmp"  { return [ get_template 1 2 ] }
    "fp_"    { return [ get_template 1 6 ] }
    "fpmul"  { return [ get_fpmul_params ] }
    "fpadd|fpsub"  { return [ get_fpaddsub_params ]  }
  }
}

# ===================================================================== #
proc main {} {
  set fname [ file tail [info script ] ]
  set fname_root [ file rootname $fname ]

  foreach c [ get_params "$fname_root" ] {
        puts "$fname_root $c"
  }
}


# ===================================================================== #
#         Main 
# ===================================================================== #
set homedir   "[get_homedir]"
set rootlevel "$homedir/$PATH_LEVEL"

set linked_fname [ get_link_from [ info script ]]

# set WIDTH { Custom 25 9 Custom 54 12 }
set WIDTH { Single 24 8 Double 53 11 } 
set WIDTH { Single 24 8 }
set WIDTH { Double 53 11 }

# puts "linked: $linked_fname"
# puts "argv0 : $argv0"
# puts "script: [info script]"

source "$homedir/lib/conf_variants.tcl"
# when this script is linked 

if { [ string compare $linked_fname "" ] != 0 } {
  main
} else {
  foreach f [ glob $homedir/fp*.tcl ] {
    if {[ string compare $f [info script ]] == 0 } { continue }
    puts [ exec xtclsh $f ]
  }
}
