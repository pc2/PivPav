installation.
===========

1. change the xtclsh shell in the *.tcl files
./misc/tools/replace_in_files.sh /pc2fs/work/user/mgrad/ISE/ISE/bin/lin64/xtclsh /opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

2. adapt the configuration of the pivpav:
vim _conf.tcl: change libtcl*
