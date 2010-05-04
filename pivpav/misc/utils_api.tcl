#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

if {  [ namespace exists "::UTILS" ] } { return }
namespace eval ::UTILS ""

proc UTILS::time_mark { }  {
  return [ clock clicks -millisec ]
}

proc ::UTILS::time_from_now { mark } {
  return "[expr ([clock clicks -millisec]-$mark)/1000.]";
}

proc ::UTILS::compress_tgz {fname} {
  set dir [ file dirname $fname]
  set fname [ file tail $fname]
  set cmd "|tar -C$dir -czf - $fname"
  # puts "[pwd] $cmd"
  set fid [ open $cmd r ]
  fconfigure $fid -translation binary -buffering none
  set bindata [ read $fid ]
  close $fid
  return $bindata
}

# extract to stdout
# @filtr  = will extract only selected files
# @fname  = output to that fname, if null then extract to stdout
# @stdout = if 0 then extract to the same file as it was compressed from
proc ::UTILS::uncompress_tgz { bindata {filtr "" } { fname "" } { stdout 1 } } {
  set cmd ""

  if { $stdout == 0 } {
    set cmd  "|tar -xzvf -" 
  } else {
    if {[ string compare $fname "" ] } {
      set cmd  "|tar -O -xzf - $filtr > $fname" 
    } else {
      set cmd "|tar -O -xzf - $filtr"
    }
  }
  # puts $cmd
  set fid  [ open $cmd "w" ]
  fconfigure $fid -translation binary
  fconfigure $fid -buffering none
  fconfigure $fid -blocking  false
  puts -nonewline $fid $bindata
  close $fid
}

proc ::UTILS::find_file { pattern } {
  if { ![ catch { set files [ glob $pattern ] } errmsg ] } {
    return $files 
  }
}

proc ::UTILS::redirect_stdout_stderr { stdout_fname stderr_fname} {
  set ::stdout_dup [ open "$stdout_fname" w ]
  set ::stderr_dup [ open "$stderr_fname" w ]
  rename ::puts ::__puts
  proc ::puts { args } {
    # do orginal behavior
    eval ::__puts $args

    #  when: puts value
    if { [ llength $args ] == 1 } {
      eval ::__puts $::stdout_dup $args

    # when: puts ... value
    } else {
      set new_line 0
      set f_idx 0
      set dup_args [\list ]

      # when: puts -nonewline 
      if { [ string compare [ lindex $args 0 ] "-nonewline" ] == 0  } {
        incr f_idx 1
        lappend dup_args "-nonewline"
        set new_line 1
      } 

      # for debugging: __puts "$new_line [ lindex $args end ]"

      # when: puts -nonewline value
      if { [ llength $args  ] == 2 && $new_line == 1 } {
        lappend dup_args $::stdout_dup
        incr f_idx 1
      } else {

        # when: puts (-nonewline)? stdout value
        if { [ string compare [ lindex $args $f_idx ] "stdout" ] == 0  } {
          lappend dup_args $::stdout_dup
          incr f_idx 1
          
        # when: puts (-nonewline)? stderr value
        } elseif { [ string compare [ lindex $args $f_idx ] "stderr" ] == 0 } {
          lappend dup_args $::stderr_dup
          incr f_idx 1
        # when: puts $fid value
        } else {
          return 
        }
      }

      # add value
      lappend dup_args [ lindex  $args $f_idx ]

      # replicate
      eval ::__puts $dup_args
    }
  }
}

proc dputs { args } {
  if { $::DEBUG == 1 } { eval puts "$args" }
}

proc dexec { args } {
  if { $::DEBUG == 1 } {
    eval $args
  }
}

proc ::UTILS::test_compress {} {
  set tmpdir [ exec mktemp -p ./ -d ]
  set dstfile "$tmpdir/blob.tgz"
  
  set fname [ lindex $::argv 0 ]
  set tgz [ ::UTILS::compress_tgz $fname ]

  set fid [ open "$dstfile" w ]
  fconfigure $fid -translation binary
  fconfigure $fid -bufferin none
  fconfigure $fid -blocking false
  puts -nonewline $fid $tgz
  close $fid
  puts "stored to: $dstfile"

  cd $tmpdir 
  set filtr ""
  set out ""
  set stdout 0
  ::UTILS::uncompress_tgz $tgz $filtr $out $stdout
}

# ############## #
# main           #
# ############## #

if { [string compare [info script] $argv0] == 0} {
  if {$argc==0} {
    puts "Usage: $argv0 filename"
    exit 1
  }

  ::UTILS::test_compress

#  redirect_stdout_stderr  stdout.txt stderr.txt
#  # 1 param
#  puts "normalka"

#  # 2 params
#  puts stdout "stdout_normalka"
#  puts -nonewline "stdout1_nonewline    \n"
#  puts stderr "stderr_normalka"

#  # 3 params
#  puts -nonewline stdout "stdout2_nonewline \n"
#  puts -nonewline stderr "stderr_nonewline"
}

