proc check_against { v pat } { 
  set v [ string tolower $v ]
  set res [ lsearch  -all -inline -regexp $v "^$pat$" ]
  if { [ string compare $res "" ] != 0 } { return $res }
  puts stderr "$v: does not match any of the patterns: $pat"
  exit 1
}

proc check_range { v from to {inc 0}} {
  if { $inc == 0 } {
    if { $v >= $from && $v <= $to } { return $v }
  } else {
    if { $v > $from && $v < $to } { return $v }
  }
  puts stderr "$v: outside range $from - $to"
  exit 1
}

proc check_bool { v } {
  check_against $v "0|1|true|false"
}

proc check_sign { v } {
  check_against $v "signed|unsigned"
}
