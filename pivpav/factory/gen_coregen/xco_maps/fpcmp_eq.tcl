source "[file dirname [info script]]/fp_operator.tcl"

rename ::XCO_MAP::getType ::XCO_MAP::getType_fpop

namespace eval XCO_MAP {
  proc getType {port_name isIn} {
    switch -- $port_name {
      "result"  { return [\list 0 0 0 0 0 ] }
      default   { return [ ::XCO_MAP::getType_fpop $port_name $isIn ] }
    }
  }
}
