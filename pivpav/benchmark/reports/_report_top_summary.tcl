#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh
# #!/Xilinx/ISE92i/bin/lin/xtclsh

# ----------
# vars
set PARSED_ARRAY 1
set NEW_TAB_BEG 1 

set fid stdin
if {[ llength $argv ] > 0 } {
  set fname [ lindex $argv 0 ]
  set fid [ open  $fname  r ]
} 

proc parse { str } {
  regsub {^\s+} $str {} str
  regsub {\s+$} $str {} str
  return $str
}

set FileContents [ read $fid ]
close $fid

set FileLines [ split $FileContents "\n" ]
foreach line $FileLines {

  # parse only 4 tables
  if { $PARSED_ARRAY > 4 } { break }

  # remove all splitting rows & whitespaces in rows
  if { [ regexp {[-+]{10,}} $line ] } { continue } 
  regsub {^\s*\|} $line {} line
  regsub {\|\s*$} $line {} line

  # puts ">>> $line"

  # when there is empty line between the tables
  # it means that the new one will begging short after
  if { [ regexp {^$} $line ]} {
    if { $NEW_TAB_BEG==0 } {
      incr PARSED_ARRAY 1
      # puts "\nnew: $PARSED_ARRAY"
      set NEW_TAB_BEG 1
    }

  # when we parse the new table
  } else {
    # skip header (1st line) of the table
    # skip also 2nd line for the 2nd and 4rth table
    if { $NEW_TAB_BEG != 0 } { 
      if { $PARSED_ARRAY == 4 && $NEW_TAB_BEG != 4  } { 
        set NEW_TAB_BEG 4 
      } elseif { $PARSED_ARRAY == 2 && $NEW_TAB_BEG != 2  } { 
        set NEW_TAB_BEG 2 
      } else { 
        set NEW_TAB_BEG 0 
      }
      # puts "NEW_TAB_BEG = $NEW_TAB_BEG"
      continue
    }
    # start navigation between columns
    set Fields [ split $line "|" ]
    foreach {var val} $Fields {
      # treat special this table
      if { ${PARSED_ARRAY} == 4 } { 
        set var "$var error"
        set val [ lindex $Fields 3  ]
      }
      regsub -all {[*:]} $var {} var
      set var [ parse $var ]
      set val [ parse $val ]
      regsub -all {\s+|-|\/} $var {_} var
      set var [ string tolower $var ]
      puts "$var=\"$val\""

      # skip rest from the 2nd table
      if { $PARSED_ARRAY == 2 } { break }
      if { $PARSED_ARRAY == 3 } { break }
      if { $PARSED_ARRAY == 4 } { break }
    }
  }
}
