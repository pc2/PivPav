#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

# ===================================================================== #
# Configure patterns and variables
# Patterns will be matched in sequential manner. One after the another.
# Therefor they have to appear in proper order.
# If pattern found, result will be stored to variable.
# ===================================================================== #
#     pattern       |                       variable

set config [list \
  {Total estimated power consumption .* ([\d\.]+)}             "t_p"   \
  {Total Vccint\s+([\d\.]+)V[\s\|]+([\d\.]+)[\s\|]+([\d\.]+)}  {vint_t vint_i vint_p} \
  {Total Vccaux\s+([\d\.]+)V[\s\|]+([\d\.]+)[\s\|]+([\d\.]+)}  {vaux_t vaux_i vaux_p} \
  {Total Vcco25\s+([\d\.]+)V[\s\|]+([\d\.]+)[\s\|]+([\d\.]+)}  {vo25_t vo25_i vo25_p} \
  {Clocks .* ([\d\.]+)}             "clk_t"   \
  {DCM .* ([\d\.]+)}                "dcm_t"   \
  {IO .* ([\d\.]+)}                 "io_t"    \
  {Logic .* ([\d\.]+)}              "logic_t" \
  {Signals .* ([\d\.]+)}            "signals_t"   \
  {Quiescent Vccint\s+([\d\.]+)V[\s\|]+([\d\.]+)[\s\|]+([\d\.]+)}  {q_vint_t q_vint_i q_vint_p} \
  {Quiescent Vccaux\s+([\d\.]+)V[\s\|]+([\d\.]+)[\s\|]+([\d\.]+)}  {q_vaux_t q_vaux_i q_vaux_p} \
  {Quiescent Vcco25\s+([\d\.]+)V[\s\|]+([\d\.]+)[\s\|]+([\d\.]+)}  {q_vo25_t q_vo25_i q_vo25_p} \
  {Estimated junction temperature .* ([\d\.]+)}            "junc_temp"   \
  {Ambient temp .* ([\d\.]+)}                              "ambient_temp"   \
  {Case temp .* ([\d\.]+)}                                 "case_temp"   \
  {Theta J-A .* ([\d\.]+)}                                 "theta_p"   \
]
set conf_num 0


# ===================================================================== #
# setup supported file type & description which will be supported
set ::ext_pat ".pwr"
set ::process_name "power"

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
