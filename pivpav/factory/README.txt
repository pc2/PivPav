This directory contains circuits and circuit generators which allow to fed the database.


# =============================================================================== # 
The structure of the database (db) is fixed.
That's why each circuit first needs to be parsed and properties of it need to be
translated to map db structure. This is achieved in automated manner with
scripts found in this dir.



# =============================================================================== # 
There are 3 scripts which allow to generate, parse and insert circuits to db in 
automated way.  This are:

./addCustomCircuit.tcl
./gen_flopoco
./gen_coregen


# =============================================================================== # 
# Custom circuits
# =============================================================================== # 
The easiest way to insert custom circuit is by using ./addCustomCircuit.tcl
Example: ./addCustomCircuit.tcl -type add -latency 0 -size 32 -fp_s -no_db -db ../test/test.db test.vhdl

This script will parse the test.vhdl file.
- will find entity, parse the ports which will be then inserted to db
- this will allow for having general interface to component allowing to connect
  it with others in automated way (hardware generators)
- some properties of the circuit can't be found by parsing the file therefor
  they have to be manually typed, in the example here we see that the script
  will be added with the "add" type (it will be used later to group the circuits
  together), we see latency = 0, and that the input databus is used to transfer
  floating point values (single).
- have a look on other settings.
- it's very easy to add circuit by typing only these properties, the access afterwards 
  to the characteristics of the circuit can be obtained with fixed api.
  You just have to mark the circuit with certain properties.


# =============================================================================== # 
# Generators
# =============================================================================== # 
Two generators can be found here, one for coregen and the other for flopoco.
It's required that this tool should be found in PATH environmental variable.

./gen_coregen.tcl - is used to dump coregen database.
                  - the implementation of it can be found in gen_coregen/ dir.
                  - it's very modular and it's very easy to adapt it to other
                    circuits
                  - it's possible to generate all variants of configuration of
                    each circuit (design space exploration).
                  - it works with coregen configuration files *.xco files
                  - the framework is written which allows to manipulate settings of this file.
                  - it allows to map and group them into buckets etc.
                  - finally the xco parser provides fixed api which allows to deliver any information about generated component.

./gen_flopoco.sh  - this script generates set of flopoco circuits and inserts
                  them into (db).




# =============================================================================== # 
# coregen
# =============================================================================== # 

######## working with the xco

> cd gen_coregen && ./add.tcl --help
(Modify and) show xco configuration for 'add' operator
usage: ./add.tcl   <-list_params>  <param value>
         -list_params  = prints all available parameters
         param         = pattern which will be used to find xco variable
         value         = this value will be assigned to parameter


####### To list mappings & params of xco file

$ ./add.tcl --list_params
Predefined mappings:
      size                      -> a_width
      port_a_size               -> a_width
      port_a_sign               -> a_type
      port_b_size               -> b_width
      port_b_sign               -> b_type
      carry_in                  -> c_in
      carry_out                 -> c_out
All variables:
      ainit_value               = 0
    * c_out                     = false
      sinit_value               = 0
      b_constant                = false
    * b_type                    = Signed
      sync_ce_priority          = Sync_Overrides_CE
      implementation            = Fabric
      out_width                 = 32
      latency_configuration     = Manual
    * a_width                   = 32
      borrow_sense              = Active_Low
    * c_in                      = true
    * b_width                   = 32
      sync_ctrl_priority        = Reset_Overrides_Set
    * a_type                    = Signed
      bypass                    = false
      bypass_ce_priority        = CE_Overrides_Bypass
      component_name            = add
      sclr                      = false
      add_mode                  = Add
      b_value                   = 00000000000000000000000000000000
      sset                      = false
      sinit                     = false
      bypass_sense              = Active_High
      latency                   = 1
      ce                        = true


####### To print the xco configuration

$ ./add.tcl 
# BEGIN Project Options
SET verilogsim                = False
SET devicefamily              = virtex4
SET speedgrade                = -11
SET createndf                 = False
SET designentry               = VHDL
SET flowvendor                = Other
SET vhdlsim                   = True
SET device                    = xc4vfx100
SET foundationsym             = False
SET implementationfiletype    = Ngc
SET addpads                   = False
SET asysymbol                 = True
SET busformat                 = BusFormatAngleBracketNotRipped
SET formalverification        = False
SET package                   = ff1152
SET simulationfiles           = Behavioral
SET removerpms                = False
# END Project Options
# BEGIN Select
SELECT Adder_Subtracter family Xilinx,_Inc. 11.0
# END Select
# BEGIN Parameters
CSET ainit_value               = 0
CSET c_out                     = false
CSET sinit_value               = 0
CSET b_constant                = false
CSET b_type                    = Signed
CSET sync_ce_priority          = Sync_Overrides_CE
CSET implementation            = Fabric
CSET out_width                 = 32
CSET latency_configuration     = Manual
CSET a_width                   = 32
CSET borrow_sense              = Active_Low
CSET c_in                      = true
CSET b_width                   = 32
CSET sync_ctrl_priority        = Reset_Overrides_Set
CSET a_type                    = Signed
CSET bypass                    = false
CSET bypass_ce_priority        = CE_Overrides_Bypass
CSET component_name            = add
CSET sclr                      = false
CSET add_mode                  = Add
CSET b_value                   = 00000000000000000000000000000000
CSET sset                      = false
CSET sinit                     = false
CSET bypass_sense              = Active_High
CSET latency                   = 1
CSET ce                        = true
# END Parameters
GENERATE
# CRC: 30621365


####### To change configuration.
* carry_in  : is a mapping (it does not exist physically in the *.xco file - virtual setting)
* ce        : real setting from the xco file

Notice that: it's possible with this generate other circuits just by changing the size of input database.


$ ./add.tcl carry_in false ce false
# BEGIN Project Options
SET verilogsim                = False
SET devicefamily              = virtex4
SET speedgrade                = -11
SET createndf                 = False
SET designentry               = VHDL
SET flowvendor                = Other
SET vhdlsim                   = True
SET device                    = xc4vfx100
SET foundationsym             = False
SET implementationfiletype    = Ngc
SET addpads                   = False
SET asysymbol                 = True
SET busformat                 = BusFormatAngleBracketNotRipped
SET formalverification        = False
SET package                   = ff1152
SET simulationfiles           = Behavioral
SET removerpms                = False
# END Project Options
# BEGIN Select
SELECT Adder_Subtracter family Xilinx,_Inc. 11.0
# END Select
# BEGIN Parameters
CSET ainit_value               = 0
CSET c_out                     = false
CSET sinit_value               = 0
CSET b_constant                = false
CSET b_type                    = Signed
CSET sync_ce_priority          = Sync_Overrides_CE
CSET implementation            = Fabric
CSET out_width                 = 32
CSET latency_configuration     = Manual
CSET a_width                   = 32
CSET borrow_sense              = Active_Low
CSET c_in                      = false
CSET b_width                   = 32
CSET sync_ctrl_priority        = Reset_Overrides_Set
CSET a_type                    = Signed
CSET bypass                    = false
CSET bypass_ce_priority        = CE_Overrides_Bypass
CSET component_name            = add
CSET sclr                      = false
CSET add_mode                  = Add
CSET b_value                   = 00000000000000000000000000000000
CSET sset                      = false
CSET sinit                     = false
CSET bypass_sense              = Active_High
CSET latency                   = 1
CSET ce                        = false
# END Parameters
GENERATE
# CRC: 30621365


####### Adding new circuit

Just link it to operator.tcl
Afterwards it will automatically appear when: $ ./gen_coregen.tcl -list_ops


$ ls -l
total 84
lrwxrwxrwx 1 mgrad users    12 Dec 11 09:55 add.tcl -> operator.tcl
lrwxrwxrwx 1 mgrad users    12 Dec 11 09:55 div.tcl -> operator.tcl
lrwxrwxrwx 1 mgrad users    12 Dec 11 09:55 fpadd.tcl -> operator.tcl
lrwxrwxrwx 1 mgrad users    12 Dec 11 09:55 fpcmp_eq.tcl -> operator.tcl
...

Then add default xco configuration to xco_files/ directory

If you want to create virtual setting (mapping) then have a look to xco_maps/fp_operator.tcl


####### Design space exploration
It is possible to generate variations (combinations) of xco settings.
$ cd circuits/gen_coregen/variants

$ ./add.tcl  | tail -4
add a_type Unsigned b_type Unsigned implementation Fabric a_width 32 b_width 32 out_width 32 latency 31 
add a_type Unsigned b_type Unsigned implementation Fabric a_width 32 b_width 32 out_width 32 latency 32 
add a_type Unsigned b_type Unsigned implementation DSP48 a_width 32 b_width 32 out_width 32 latency 0 c_en false
add a_type Unsigned b_type Unsigned implementation DSP48 a_width 32 b_width 32 out_width 32 latency 1 

This configuration can be directly used by gen_coregen/add.tcl script to generate *.xco configuration as shown above.
Further, it can be used by circuits/gen_coregen.tcl to run FPGA CAD tools on it and store results into DB.

$ ./gen_coregen.tcl add
# ======================================================================================= #
# Project directory
# ======================================================================================= #
* Removing directory                       ./../_gen_cg_compile/add
* Creating directory                       ./../_gen_cg_compile/add

# ======================================================================================= #
# XCO configuration
# ======================================================================================= #
* Load parser:                             ./../circuits/gen_coregen/lib/xco_parser.tcl
* Load mapper:                             ./../circuits/gen_coregen/xco_maps/add.tcl
* Generate with:                           ./../circuits/gen_coregen/add.tcl
* Parse xco configuration                 

# ======================================================================================= #
# Generating circuit
# ======================================================================================= #
* Elapsed time:                            24.881 sec

# ======================================================================================= #
# Parsing the top entity of the circuit
# ======================================================================================= #
* Parsing vhdl:                            ./../_gen_cg_compile/add/compile/add.vhd
* Detecting configuration of the ports 
           name | isIn |                           type | size |  clk |   ce |  rst |        val | cons | sign | unsign |   fp |  exp |  fra |  reg
               a |    1 |  std_logic_VECTOR(31 downto 0) |   32 |    0 |    0 |    0 |            |    0 |    1 |    0 |    0 |    0 |    0 |    0
               b |    1 |  std_logic_VECTOR(31 downto 0) |   32 |    0 |    0 |    0 |            |    0 |    1 |    0 |    0 |    0 |    0 |    0
             clk |    1 |                      std_logic |    1 |    1 |    0 |    0 |            |    0 |    0 |    0 |    0 |    0 |    0 |    0
            c_in |    1 |                      std_logic |    1 |    0 |    0 |    0 |            |    0 |    0 |    0 |    0 |    0 |    0 |    0
              ce |    1 |                      std_logic |    1 |    0 |    1 |    0 |            |    0 |    0 |    0 |    0 |    0 |    0 |    0
               s |    0 |  std_logic_VECTOR(31 downto 0) |   32 |    0 |    0 |    0 |            |    0 |    0 |    0 |    1 |    0 |    0 |    1

# ======================================================================================= #
# Storing to database
# ======================================================================================= #
* Storing into db component: add
* Success, circuit rowid=113



####### Changing the default configuration
Just edit the circuits/../_conf.tcl script
Normally many default settings can be overwritten with command line options.

