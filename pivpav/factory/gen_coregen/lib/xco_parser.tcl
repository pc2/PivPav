#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

####################
# Parser functions #
####################
namespace eval XCO_PARSER {

  proc SET {name = args } {
    eval  namespace eval ::SET { "set _$name {$args}" }
  }

  proc SELECT { args } { 
    eval namespace eval ::SELECT { "set _SELECT {$args}" }
  }

  proc CSET { args } {
    set l [ split $args = ]
      set name  [ lindex $l 0 ]
      set value [ lindex $l 1 ]
      eval  namespace eval ::CSET { "set _$name $value" }
  }
  proc GENERATE {} {}

  proc parse {fname} {
    set fid [ open $fname r ]
    set data [ read $fid ]
    close $fid

    if {[regexp {CRC:\s*(\S+)} $data {} crc] == 0} {
      puts $data
      puts stderr "Can't find CRC value"
      exit 1
    }
    eval namespace eval ::CRC { "set _CRC {$crc}" }

    source $fname
  }
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
  set fname [ lindex $::argv 0 ]
  XCO_PARSER::parse $::fname

  source xco_writer.tcl
  xco_write
}
