#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

# ===================================================================== #
# Configure patterns and variables
# Patterns will be matched in sequential manner. One after the another.
# Therefor they have to appear in proper order.
# If pattern found, result will be stored to variable.
# ===================================================================== #
#     pattern       |                       variable

set config [list \
  {Number of 4 input LUTs:\s+(\d+)}             "n_lut"   \
  {Number of occupied Slices:\s+(\d+)}          "n_slice" \
  {Number of Slices.*related logic:\s+(\d+)}    "n_l_rel" \
  {Number of Slices.*unrelated logic:\s+(\d+)}  "n_l_unrel" \
  {Number of bonded IOBs:\s+(\d+)}              "n_io_buf" \
  {Number used as BUFGs:\s+(\d+)}               "n_bufg" \
  {Number used as BUFGCTRLs:\s+(\d+)}           "n_bufgctrl" \
  {Total equivalent gate count.*:\s+(\d+)}      "n_gate" \
  {Peak Memory Usage:\s+(\d+) MB}               "n_mem" \
  {Total REAL time.*:\s+(\d+) secs}             "t_real" \
  {Total CPU time.*:\s+(\d+) secs}              "t_cpu" \
]
set conf_num 0


# ===================================================================== #
# setup supported file type & description which will be supported
set ext_pat ".map"
set process_name "mapping"

# ===================================================================== #
# return "" if this is script is not linked
# return "linked fname" otherwise
proc is_linked {fname} {
  set rc [ catch {set link [ file link $fname ]} ]
  if {$rc == 0} {
    return $link
  }
  return ""
}

# ===================================================================== #
# return path to the script
proc get_homedir {} {
  upvar #0 argv0 script_name

  # when linked
  set fname [ is_linked $script_name ] 
  if { [ string compare $fname "" ] != 0 } {
    set script_name $fname
  }
  # find homedir of the script
  set HOMEDIR [ file dirname $script_name ]
  return $HOMEDIR
}


# ===================================================================== #
#         Main 
# ===================================================================== #
set homedir [get_homedir]
source "$homedir/report.tcl"

# If this script was executed, and not just "source"'d, handle argv
set linked_fname [ is_linked [info script ]]
if { [ string compare $linked_fname "" ] != 0 || [string compare [info script] $argv0] == 0} { 
  main
}
