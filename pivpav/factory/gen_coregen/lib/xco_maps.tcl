# port_a_sign
# port_b_sign
# port_c_in_sign
# c_a_exponent_width
# c_a_fraction_width
# a_precision_type
# port_s_sign
# c_result_exponent_width
# c_result_fraction_width
# result_precision_type
# pipeline

# component_name
# operation
# latency
# inputs_rate


# =========================================================
# default mappings between xco file and general params
# =========================================================v
if {  [ namespace exists "XCO_MAP" ] } { return }
namespace eval XCO_MAP {

######################################### 
# find all variables matching given pattern
######################################### 
proc xco_varsearch { pat } {
  set var_name ""
  if {[catch {lset var_name [ info vars $pat ] } ] == 1} {
    puts stderr "Pattern $pat not found"
    # exit 1
  }
  # puts [ format "pat: %.25s var_name: %-20s  size: %s" $pat $var_name [ llength $var_name ] ]
  return $var_name
}

######################################### 
# key/value mapping between acronyms
######################################### 
proc xco_acronyms { name } {
 # acronyms
  switch -glob $name {
    name     { return "component_name" }
    sign     { return "type" }
    type     { return "sign" }
    size     { return "width" }
    width    { return "size" }
    latency  { return "pipeline" }
    pipeline { return "latency" }
    default  { return "" }
  }
}


############################################################ 
# xco_defmap = main procedure
############################################################ 
# tries to match $name to parameter from *.xco file.
# this is regexp searching. Many parameters can be selected.
# if so then they are limited by $args patterns.
# result = parameter name only when 1 found.
############################################################ 
proc xco_defmap { name args } {
  set name [ string tolower $name ]
  set pat "::CSET::_$name" 
  set var_name ""

  # try to find exactly match
  set var_name [ xco_varsearch $pat ]
  if { [ llength $var_name ] == 1 } { return $var_name } 

  set pat "::CSET::_*$name*" 

  # if non found, try to replace pat with acronym
  if { [ llength $var_name ] == 0 } {
    set acro [ xco_acronyms $name ]
    if { [ string compare $acro "" ] != 0 } {
      set var_name [ xco_varsearch "::CSET::_$acro*" ]
      if { [ llength $var_name ] == 1 } { return $var_name } 
    }
  }

  # limit amount of variables to 1 if many are found
  if { [ string compare $args "" ] != 0 } {
    set var_name [ lsearch -all -inline -regexp $var_name "$args" ]
  }
  set size [ llength $var_name ]
  switch $size {
    0 { 
       # puts stderr "No variables found for pattern: $pat";
        return ""
      }
    1 { return $var_name }
    default { 
      puts stderr "Too many variables matching pattern '$pat' were found:"
      puts stderr "\t[ join [ split $var_name ] \n\t]"; 
      exit 1 
    }
  }
}

proc xco_get {param } {
  puts "xco_maps.tcl/xco_get param=$param"
  set t [ xco_defmap $param ]
  return [ set $t ]
}

proc xco_set {param value} {
  set [ xco_defmap $param ] $value
}

# ====================================================================
# return type of port, type can be diff for input and output
# for example when converting values or when cmp
proc getType {port_name isIn} {
  set isSign   0
  set isUnsign 0
  set isFP     0
  set exp_sz   0
  set fra_sz   0

  switch -regexp -- $port_name {
    "^(clk|clock|rst|ce)$" { return [\list 0 0 0 0 0 ] } 
  }

  # integer operator should have defined that
  set v [ xco_get [ format "port_%s_sign" $port_name]  ]
  if {[ string compare $v "" ] != 0 } {
    if { [regexp -nocase {sign} $v ] } { set isSign 1 } else  { set isUnsign 1 }
  } else {
  # float operator
    if {$isIn == 1} {
      set exp_sz [ xco_get c_a_exponent_width]
      set fra_sz [ xco_get c_a_fraction_width]
      set in_type [ xco_get a_precision_type ]
      if {[regexp {Int32} $in_type {} ]} {
        set isSign 1
      } else {
        set isFP 1
      }
    } else {
      set exp_sz [ xco_get c_result_exponent_width] 
      set fra_sz [ xco_get c_result_fraction_width]
      set out_type [ xco_get result_precision_type ]
      if {[regexp {Int32} $out_type {} ]} {
        set isSign 1
      } else {
        set isFP 1
      } 
    }

    if {[ string compare $exp_sz "" ] == 0  && [ string compare $fra_sz "" ] == 0} {
      # no infos found, but tried to match before (overwritten)
      set exp_sz 0
      set fra_sz 0
    }
  }
  return [\list $isSign $isUnsign $isFP $exp_sz $fra_sz]
}

############################################################ 
# return info about buffered output
############################################################ 
proc isOutputReg {} {

  if {[ regexp -nocase {true} [ xco_get register_outputs ] ] } {
    return 1
  }
  set v [ xco_get latency ]
  if {$v > 0} { return 1 } else {  return 0 }
}



# end of namespace
}
