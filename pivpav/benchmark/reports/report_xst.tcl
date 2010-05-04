#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

# ===================================================================== #
# Configure patterns and variables
# Patterns will be matched in sequential manner. One after the another.
# Therefor they have to appear in proper order.
# If pattern found, result will be stored to variable.
# ===================================================================== #
#     pattern       |                       variable

set config [list \
  {^Optimization Goal\s+: (.*)}        "opt_fl_goal"       \
  {^Optimization Effort\s+: (.*)}      "opt_fl_eff"     \
  {^Power Reduction\s+: (.*)}          "opt_pwr_red"  \
  {^Keep Hierarchy\s+: (.*)}           "fl_keep_hier"      \
  {^# IOs\s+: (.*)}                    "n_io"             \
  {^# FlipFlops/Latches\s+: (.*)}      "n_ff"             \
  {^# Clock Buffers\s+: (.*)}          "n_clk_buf"        \
  {^# IO Buffers\s+: (.*)}             "n_io_buf"         \
  {Minimum period: (.*)ns}             "n_min_per"     \
  {Maximum combinational.*: (.*)(ns)}  "n_freq"           \
  {Offset:\s+(.*)ns.*= (\d+)}         {t_b_clk n_t_b_clk_lev_l}    \
  {Total.*\((.*)ns logic, (.*)ns route} {t_b_clk_l t_b_clk_route} \
  {^\s+\((.*)% logic, (.*)%}            {n_t_b_clk_l_proc n_t_b_clk_route_proc} \
  {Offset:\s+(.*)ns.* = (\d+)}         {t_a_clk n_t_a_clk_lev_l}         \
  {Total.*\((.*)ns logic, (.*)ns route} {t_a_clk_l t_a_clk_route} \
  {^\s+\((.*)% logic, (.*)%}            {n_t_a_clk_l_proc n_t_a_clk_route_proc} \
  {Total CPU .* ([\d\.]+)}             "t_cpu" \
  {Total memory .* (\d+)}              "n_mem" \
  {Number of errors .* (\d+) \(}       "n_error" \
  {Number of warnings .* (\d+) \(}     "n_warn" \
  {Number of infos .* (\d+) \(}        "n_info" \
]
set conf_num 0

# ===================================================================== #
# setup supported file type & description which will be supported
set ext_pat ".syr"
set process_name "synthesis"

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
