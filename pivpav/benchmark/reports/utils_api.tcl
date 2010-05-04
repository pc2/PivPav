if {  [ namespace exists "REPORT_UTILS" ] } { return }
namespace eval REPORT_UTILS ""
# ===================================================================== #
proc get_varnames { } {
  upvar #0 config config
  set l ""
  foreach {p v} $config {
    lappend l $v
  }
  return $l
}

# ===================================================================== #
# num = pattern number, default 0
# returns: patter variable_name
proc get_patval { {num 0}} {
  upvar #0 config config
  set id [ expr $num * 2 ]
  set id_next [ expr $id + 1]
  return [ lrange $config $id $id_next ]
}

