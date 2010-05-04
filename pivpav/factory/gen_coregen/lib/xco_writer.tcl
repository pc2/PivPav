# prints out 
proc listnsvars {{ns ::} {no_ns 0}} {
  set RE "^::${ns}::_"
  foreach v [ info vars ${ns}::*] {
    regsub $RE  $v {} var
    if { $no_ns == 0 } {
      puts [ format "%.10s %-25s = %s" $ns $var [ set $v ] ]
      # puts stdout "${ns} $var = [set $v]"
    } else {
      puts stdout "$var [set $v]"
    }
  }
}

proc xco_write {} {
  puts "# BEGIN Project Options"
  listnsvars  SET
  puts "# END Project Options"
  puts "# BEGIN Select"
  listnsvars  SELECT 1
  puts "# END Select"
  puts "# BEGIN Parameters"
  listnsvars  CSET
  puts "# END Parameters"
  puts "GENERATE"
  puts "# CRC: $::CRC::_CRC"
}

####################
# main             # 
####################
# If this script was executed, and not just "source"'d, handle argv
if { [string compare [info script] $::argv0] == 0} {
  if { [ info exists argc ] && $::argc!=1} {
    puts stderr "Usage $argv0 file.xco"
    exit 1
  }
  source "xco_parser.tcl"
  set fname [ lindex $::argv 0 ]
  source $fname
  xco_write
}
