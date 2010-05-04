bench.tcl
=============

It prepares the circuit obtained from DB to be compiled.
Internally it uses ise.tcl tool to compile.

The preparation consist of wrapping (tool: bin/wrapper) the circuit.
This is necessary for obtaining timing characteristics for combinational circuits.
This have to be encapsulated with registers on inputs and outputs.

bench selects appropriate design goal for the FPGA CAD algorithms.
It means that it can control the settings of them.
Set of the settings is called "design goal".
Some of them can be found in design_goals/ dir.


ise.tcl
===========

This is a wrapper around Xilinx ISE tool.
It is used to compile different projects.
The projects can consist of xco (coregen configuration files) and vhdl files.
The different FPGA CAD algorithms are used to compile these.

It has the ability to control each of the FPGA CAD algorithm by changing the
settings of it.
