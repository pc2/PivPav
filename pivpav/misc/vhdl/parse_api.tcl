# Usage: getComponent <filename.vhd>
# it parses entity in that file
# returns list like that: componentName {XXX}
#  where ports are descr by {XXX} = {name dir, type, size, val}

namespace eval ask {

  proc get_ans { varname rexp {no 0 } } {
    upvar $varname localVar
    incr no
    set localVar [ gets stdin ] 
    if { ! [ regexp -nocase "${rexp}" $localVar ] } {
        if { $no > 3 } { puts stdout "ERROR" ;  exit }
        puts -nonewline "\[$no] Value '$localVar' invalid, try again $rexp: "
        flush stdout
        set localVar [ get_ans $varname $rexp $no ] 
    }
    # needed for recurrence
    return $localVar
  }

  proc getType { port_name in } {
    puts "\nPort '$port_name' is it"
    puts -nonewline " - Floating Point (not integer)?       \[0|1]" ;  flush stdout;  get_ans isFP "\[0|1]"
    if {$isFP} {
      puts -nonewline " - size of the exponenta? \[0-53]" ;  flush stdout ; get_ans exp_sz "\[0-53]"
      puts -nonewline " - size of the fraction?  \[0-53]" ;  flush stdout  ; get_ans fra_sz "\[0-53]"
      return [\list 0 0 $isFP $exp_sz $fra_sz ] 
    } else {
      puts -nonewline " - Signed port ?   \[0|1] " ; flush stdout ; get_ans isSigned "\[0|1]"
      puts -nonewline " - Unsigned port ? \[0|1] " ; flush stdout ; get_ans isUnSigned "\[0|1]"
      return [\list $isSigned $isUnsigned 0 0 0 ] 
    }
  }

  proc isOutputReg {} { 
      puts -nonewline " Are the output registered (buffered) \[0|1] " ; flush stdout ; get_ans isReg "\[0|1]"
      return $isReg 
  }
}

####################
# Parse ports      #
####################
proc getPorts { _ports } { 
  # remove: 'port(' .. ');' parts
  regsub -nocase {\mport\M\s*\(} $_ports {} _ports
  regsub -nocase {\);$} $_ports {} _ports
  set i 0

  # each line ends with ; end corresponds to single port entry
  foreach port [ split $_ports ";" ] {
    set name ""
    set dir  ""
    set type ""
    set size 1
    set val  ""

    incr i
    # remove white spaces from the beggining
    regsub -nocase {^\s+} $port {} port
    # parse
#    regexp -nocase {^(.*)\s*:\s*(\S+)\s+(.*)$} $port {} name dir type
    regexp -nocase {^([a-zA-Z_\-]+)\s*:\s*(\S+)\s+(.*)$} $port {} name dir type
    set dir  [ string tolower $dir ]
    # puts "$i: $port"
    # puts "   $name"
    # puts "   $dir"

    # find default value
    if { [ regexp -nocase {^(.*)\s*:=\s*(.*)$} $type {} type val] } {
      if {[ regexp {^'(.*)'$} $val {} tmp ]} { set val $tmp }      
      if {[ regexp {^\"(.*)\"$} $val {} tmp ]} { set val $tmp }      
      # puts "   val: $val"
    }
    # puts "   type: $type"

    # find size
    #  if: std_logic -> 1
    #  if: (31 downto 0)  -> 32
    #  if: (32+32+2 downto 0) -> 67
    if { [ regexp -nocase {([\d\+]+)\s*(\S+)\s*(\d+)} $type {} from d to] } {
      set d [ string tolower $d ]
      if { [ string compare $d "downto" ] == 0 }  {
        set size [ expr  $from - $to + 1  ]
      } else {
        set size [ expr $to - $from + 1 ]
      }
      # puts "   dir: $d"
      # puts "   size: $size"
    }
    regsub {\s+$} $type {} type

    # if: clk, rst : in std_logic ..
    foreach sig [ split $name "," ] {
      # remove spaces at the end
      regsub -nocase {\s+$} $sig {} sig
      regsub -nocase {^\s+} $sig {} sig
      lappend res  [list "$sig" "$dir" "$type" "$size" "$val" ]
    }
  }
  return $res
}

# ============================================================= #
# Parse the VHDL and copy the part corresponding to the entity
# ============================================================= #
proc getComponent { fname } {
  set ComponentName "" 
  set _parsePorts false
  set _ports ""
  set  i 0 

  set fid [ open $fname r ]
  set FileContents [ read $fid ]
  close $fid

  set FileLines [ split $FileContents "\n" ]
  foreach line $FileLines {

    # find begining of the entity
    if {[ regexp -nocase {\s*entity\s*(\S+)\s*is} $line line name ]} {
      set ComponentName $name
      set _ports ""
      set _parsePorts true
      # puts "beg: $line"
      continue
    }

    # find end of the entity
    if {$_parsePorts} { 
      if {[ regexp -nocase {^\s*end\s+\S+.*;} $line ]} {
        if {[ regexp {:} $line ] == 0 } {
          set results($ComponentName) $_ports
          set _parsePorts false
            # puts "end found: $line"
            # puts "Found entity for: $ComponentName"
            # puts $_ports
          continue
        }
      }
    }

    # store ports
    if {$_parsePorts} {
      append _ports $line
    }
  }
  if {[ array size results ] > 1 } {
    # puts stderr " =========================================================== "
    puts stderr " !!! WARNING: Many entities found: [array size results]"
    puts stderr " !!! Assuming that the top entity is the last one which is: '$ComponentName'"
    puts stderr "\n"
    # puts stderr " ===========================================================\n"
  }
  set lports [ getPorts $_ports ]
  return [list $ComponentName $lports]
}


####################
# main             # 
####################
# If this script was executed, and not just "source"'d, handle argv
if { [string compare [info script] $argv0] == 0} {
  if { [ info exists argc ] && $argc!=1} {
    puts stderr "Usage $argv0 file.vhd"
    exit 1
  }

  source ports_api.tcl

  set fname [ lindex $argv 0 ]
  set op [ getComponent $fname ]
  set ::op_name  [ lindex $op 0 ]
  set ::op_ports [ lindex $op 1 ]

  ports_print $::op_ports
  exit

  puts "* Detecting configuration of the ports "
  set ::op_ports_att [ ports_attributes $::op_ports ::ask ]

  # if output signal has no type then assume that it's the same as input
  set ::op_ports_att [ ports_correct_output_type $::op_ports_att ] 
  ports_print $::op_ports_att
}
