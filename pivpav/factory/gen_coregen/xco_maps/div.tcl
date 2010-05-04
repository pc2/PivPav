# ====================================================================
# mappings for add component between xco file (coregen) and
# general parameters. They overwrite lib/xco_maps.tcl default settings.
# ====================================================================

# latency = c_rate / clock_per_division
# pipeline = clocks from input to output

namespace eval XCO_MAP {

proc xco_get {param args} {
  switch -glob $param {
    operation    { return "div" }
    size         { return $CSET::_dividend_and_quotient_width   }
    port_a_size  { return $CSET::_dividend_and_quotient_width   }
    port_a_sign  { return $CSET::_operand_sign }
    port_b_size  { return $CSET::_dividend_and_quotient_width }
    port_b_sign  { return $CSET::_operand_sign }
    carry_in     { return 0 }
    carry_out    { return 0 }
    inputs_rate  { return $CSET::_clocks_per_division }
    # when there is mapping 1:1
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
    clock_enable { set CSET::_ce             $value }
    carry_in     { }
    carry_out    { }
    output_size  { set CSET::_dividend_and_quotient_width $value }
    port_a_size  { set CSET::_dividend_and_quotient_width $value }
    port_b_size  { set CSET::_dividend_and_quotient_width $value }
    port_a_sign  { set CSET::_operand_sign $value }
    port_b_sign  { set CSET::_operand_sign $value }

    latency { 
      set CSET::_latency $value
      if { $value == 0 } { 
        set CSET::_ce    "false"
      } 
    }

    inputs_rate { 
      set CSET::_clocks_per_division $value
    }

    default     { 
      set varname [ xco_defmap $param ]; 
      set $varname $value
    }
  }
}

}
