# ====================================================================
# mappings for add component between xco file (coregen) and
# general parameters. They overwrite lib/xco_maps.tcl default settings.
# ====================================================================

namespace eval XCO_MAP {


proc xco_get {param args} {
  switch -glob $param {
    operation    { return "add" } 
    size         { return $CSET::_a_width   }
    port_a_size  { return $CSET::_a_width   }
    port_a_sign  { return $CSET::_a_type    }
    port_b_size  { return $CSET::_b_width   }
    port_b_sign  { return $CSET::_b_type    }
    carry_in     { return $CSET::_c_in  }
    carry_out    { return $CSET::_c_out }
    inputs_rate  { return 0 }
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
    port_a_size  { set CSET::_a_width        $value }
    port_a_sign  { set CSET::_a_type         $value }
    port_b_size  { set CSET::_b_width        $value }
    port_b_sign  { set CSET::_b_type         $value }
    clock_enable { set CSET::_ce             $value }
    carry_in     { set CSET::_c_in  $value }
    carry_out    { set CSET::_c_out $value  }
    output_size  { set CSET::_out_width    $value }

    port_const  { 
      set CSET::_b_constant true
      set CSET::_b_value    $value
    }

    latency { 
      set CSET::_latency         $value
      if { $value == 0 } { 
        # puts "* combinatorial"
        set CSET::_ce    "false"
      } 

    }
    default     { 
      set varname [ xco_defmap $param ]; 
      set $varname $value
    }
  }
}

# ======================================== #
# Custom proc for checking values
# ======================================== #

proc check_sign { v } {
  check_against $v "signed|unsigned"
}


# end of namespace
}
