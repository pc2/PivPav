# ====================================================================
# mappings for mul component between xco file (coregen) and
# general parameters. They overwrite lib/xco_maps.tcl default settings.
# ====================================================================

# we can't simply map one single param to the other
# this has to be done in this way, where one param has influence on many.
# therefor we can't use only hash to map params between each other.

namespace eval XCO_MAP {

proc xco_get {param args} {
  switch -glob $param {
    operation    { return "mul" }
    size         { return $CSET::_portawidth   }
    latency      { return $CSET::_pipestages }
    port_a_size  { return $CSET::_portawidth   }
    port_b_size  { return $CSET::_portbwidth   }
    port_a_sign  { return $CSET::_portatype    }
    port_b_sign  { return $CSET::_portbtype    }
    clock_enable { return $CSET::_clockenable  }
    carry_in     { return "" }
    carry_out    { return "" }
    output_size  { return [ expr $CSET::_outputwidthhigh - $CSET::_outputwidthlow + 1] }
    inputs_rate  { return 0 }
   default      { 
      set varname [ XCO_MAP::xco_defmap $param $args ] 
      if {[string compare $varname "" ] != 0 } {
        return [ set $varname ]
      }
      return ""
   }
  }
}


proc xco_set {param value} {
  switch -glob $param {
    name         { set CSET::_component_name  $value }
    port_a_size  { set CSET::_portawidth    [ check_range $value 1 255 ] }
    port_a_sign  { set CSET::_portatype     [ check_sign  $value ]}
    port_b_size  { set CSET::_portbwidth    [ check_range $value 1 255 ] }
    port_b_sign  { set CSET::_portbtype     [ check_sign  $value ] }
    clock_enable { set CSET::_clockenable    [ check_bool  $value ] }
    carry_in     { set CSET::_carry_borrow_input [ check_bool $value ] }
    carry_out    { set CSET::_carry_borrow_output[ check_bool $value ] }
    output_size  { 
      set CSET::_outputwidthhigh [expr $value-1]
      set CSET::_outputwidthlow  0
    }

    port_const  { 
      set CSET::_port_b_constant true
      set CSET::_port_b_constant_value $value
    }

    latency { 
      set CSET::_pipestages $value
      if { $value == 0 } { 
        # puts "* combinatorial"
        xco_set clock_enable "false"
      }
    }
    default     { 
      set varname [ xco_defmap $param ]; 
      set $varname $value
    }
  }
}
}
# ======================================== #
# Custom proc for checking values
# ======================================== #
