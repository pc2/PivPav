#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

# ===================================================================== #
# Configure patterns and variables
# Patterns will be matched in sequential manner. One after the another.
# Therefor they have to appear in proper order.
# If pattern found, result will be stored to variable.
# ===================================================================== #
#     pattern       |                       variable

set config [list \
  {All constraints were (met).}   "constr" \
  {^Clk [\s\|]+([\d\.]+)}         {n_min_per} \
  {Peak Memory Usage:\s+(\d+)}     {n_mem} \
]
set conf_num 0


# ===================================================================== #
# setup supported file type & description which will be supported
set ext_pat ".twr"
set process_name "timing"

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
