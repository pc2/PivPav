# 
# set_process_props
# 
# This procedure sets properties as requested during script generation (either
# all of the properties, or only those modified from their defaults).
# 
project set "Max Fanout" "100000" -process "Synthesize - XST"
project set "Global Optimization" "Speed" -process "Map"
project set "Optimization Effort" "High" -process "Synthesize - XST"
project set "Optimization Strategy (Cover Mode)" "Speed" -process "Map"
project set "Perform Timing-Driven Packing and Placement" "true" -process "Map"
project set "Register Balancing" "Yes" -process "Synthesize - XST"
project set "Automatic BRAM Packing" "true" -process "Synthesize - XST"
project set "Pack I/O Registers into IOBs" "No" -process "Synthesize - XST"
project set "Power Reduction" "true" -process "Synthesize - XST"
project set "Map Effort Level" "High" -process "Map"
project set "Combinatorial Logic Optimization" "true" -process "Map"
project set "Power Reduction" "true" -process "Map"
project set "Register Duplication" "On" -process "Map"
project set "Power Reduction" "true" -process "Place & Route"
project set "Place & Route Effort Level (Overall)" "High" -process "Place & Route"
project set "Extra Effort" "Normal" -process "Map"
project set "Extra Effort (Highest PAR level only)" "Normal" -process "Place & Route"

