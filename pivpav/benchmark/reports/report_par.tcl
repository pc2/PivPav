#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh


# ===================================================================== #
# Configure patterns and variables
# Patterns will be matched in sequential manner. One after the another.
# Therefor they have to appear in proper order.
# If pattern found, result will be stored to variable.
# ===================================================================== #
#     pattern       |                       variable

set config [list \
  {Number of BUFGs \s+ (\d+)}           "n_bufg"         \
  {Number of ILOGICs\s+ (\d+)}          "n_i_l"          \
  {Number of External IOBs\s+ (\d+)}    "n_e_io_buf"     \
  {Number of LOCed IOBs \s+ (\d+)}      "n_loc_io_buf"   \
  {Number of OLOGICs\s+ (\d+)}          "n_o_logic"      \
  {Number of Slices \s+ (\d+)}          "n_slice"        \
  {Number of SLICEMs\s+ (\d+)}          "n_slicem"       \
  {Overall effort level.*:\s*(\S+)}     "opt_fl_eff"     \
  {Placer effort level.*:\s+(\S+)}      "opt_fl_placer_eff" \
  {Placer cost table entry .*:\s+(\S+)} "fl_cost_table"     \
  {Router effort level.*:\s+(\S+)}      "opt_fl_router_eff" \
  {Finished initial Timing.*: (\d+) secs}            "t_tgan_real"    \
  {Total REAL time to Placer completion: (\d+) secs} "t_placer_real"  \
  {Total CPU time to Placer completion: (\d+) secs}  "t_placer_cpu"   \
  {Total REAL time to Router completion: (\d+) secs} "t_router_real"  \
  {Total CPU time to Router completion: (\d+) secs}  "t_router_cpu"   \
  {^\|\s*(\S+)\s*\|\s*(\S+)\s*\|\s*(\S+)\s*\|\s*(\d+)\s*\|\s*(\S*)\s*\|\s*(\S*)\s*\|$} \
      {clknet resource locked n_fanout t_new_skew t_max_del} \
  {The AVERAGE CONNECTION.*: \s+ (\S+)}  "n_avg_conn_delay" \
  {The MAXIMUM PIN DELAY.*:  \s+ (\S+)}  "n_max_pin_delay"  \
  {The AVERAGE CONNECTION.*: \s+ (\S+)}  "n_avg_conn_delay_worst"   \
  {\| SETUP\s*\|\s*(\S+)ns\s*\|\s*(\S+)ns\s*\|\s+(\S+)\s*\|\s*(\S+)} \
      {t_setup_worst_slack t_setup_best t_setup_err t_setup_scr}     \
  {\| HOLD\s*\|\s*(\S+)ns\s*\|\s*\|\s+(\S+)\s*\|\s*(\S+)}            \
      {t_hold_worst_slack t_hold_err t_hold_scr}                     \
  {Total REAL time to PAR completion:\s*(\d+) secs} "t_par_real"     \
  {Total CPU time to PAR completion: (\d+) secs}  "t_par_cpu"        \
  {Peak Memory Usage:\s+(\d+)} "n_mem" \
  {Number of error messages:\s(\d+)} "n_error" \
  {Number of warning messages:\s(\d+)} "n_warn" \
  {Number of info messages:\s(\d+)} "n_info" \
]
set conf_num 0


# ===================================================================== #
# setup supported file type & description which will be supported
set ext_pat ".par"
set process_name {place and route}

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
