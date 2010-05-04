To play with the PivPav do the following:

DBNAME=/tmp/pivpav.db

1. create the circuit library:
$ ../pivpav/library/create-schema.tcl | sqlite3 $DBNAME


2. generate an example circuit with the factory:
$ ../pivpav/factory/gen_coregen.tcl -db $DBNAME add 

the same but in two steps:
$ ../pivpav/factory/gen_coregen.tcl -no_db add
$ ../pivpav/library/insert-circuit.tcl -db $DBNAME ../_db_circuits/add


3.  benchmark the circuit and store the results to the library:
$ ../pivpav/benchmark/bench.tcl 1
$ ../pivpav/library/insert-measure.tcl -db gen_output/pivpav.db gen_output/_db_circuits/measure_db_store.txt



4. parse the metadata about the circuit:
for power only:       $ ../pivpav/benchmark/reports/report_pwr.tcl    ./gen_output/_db_circuits/ise/*.pwr
for power only (sql): $ ../pivpav/benchmark/reports/report_pwr.tcl -s ./gen_output/_db_circuits/ise/*.pwr 
store all in db :     $ ../pivpav/library/insert-reports.tcl -m_id 1 -db $DBNAME ../pivpav/benchmark/_db_circuits/ise 
store all to file :   $ ../pivpav/library/insert-reports.tcl -m_id 1 -db /dev/null -f res.sql ../pivpav/benchmark/_db_circuits/ise 


5. let's see some results:
$ cat ../pivpav/library/data/create_view.sql | sqlite3 gen_output/pivpav.db 
$ echo "select * from d;" | sqlite3 gen_output/pivpav.db


# At this stage your circuit library will have one adder circuit.
# In addition it will have metadata obtained from running the FPGA CAD tool
# flow for single design goal.

# the logfiles from these comments can be found under the example/logs directory.


# ----------------------------------------------------------------------- #
Now let's play a bit with the API example tool (wrapper).

6. build and run the wrapper tool for adder
$ (mkdir ../api/wrapper/build && cd ../api/wrapper/build && cmake .. && make)
# this will register the input and the outputs for the adder
$ ../api/wrapper/build/wrapper -d $DBNAME -r -x 1

# These code which does that job has 70 lines (it's neat!)
# Have a look here: ../api/wrapper/libwrapper.cpp how to register, instantiate the ports etc.
# and into ../api/wrapper/main.cpp how to use C/C++ libraries included with the API



# ----------------------------------------------------------------------- #
To generate whole circuit library jump directly to ../pivpav/fill-library
There is seperate configuration file for tools there under _config.sh (not _conf.sh)
Edit it and then use these tools in the same order:
./0_create_conf.sh
./1_create_dbs.sh
./2_fill_coregen.sh
./2_fill_flopoco.sh



# ----------------------------------------------------------------------- #
# Each tool can be run with different commands.
# Use ./tool --help command to discover these.
# If not found then look into the source code for the usage() and parse_args() functions.

# There is tiny README.txt file in each of the command source directory.
# It covers also sometimes implementation details.



# ----------------------------------------------------------------------- #
To run all of the tools your PATH env variable needs to point to the
following:
 sqlite3
 coregen (from Xilinx)
 flopoco
 and rest of the Xilinx tools (xst, map, xtclsh, etc).



# ----------------------------------------------------------------------- #
I use the SQLITE Manager under Firefox to browse the circuit library with the GUI.
It works well and I can recommend it.
