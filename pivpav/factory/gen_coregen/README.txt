[ Intro ]
  Generate_operator are  scripts  which  with  the  help  of  coregen  utility
  create given operators.  In other words it's  a  wrapper  with  common  interface  to  the
  coregen.  We can use  it  as  an  standalone  tool  to  generate  operators.

  Coregen  has   several   different   usefull   components   which   can   be
  "grabed" and used in  project.   They  are  generated  by  the  util  called
  "coregen".  That utility is configured with the help of *.xco files  (xilinx
  configuration files). It means that we need only *.xco file + coregen and we
  can obtain given operator.

  However it does not  look  so  easy  at  it  sounds.   This  is  because
  each component in coregen has different attributes. When one think about it
  it's obvious. Comparators will have different rounding modes, adders can
  have carry chains etc. Therefor each component will have subset of xco
  configuration parameters unique only to himself. There is also subset which
  is common to all components - for example size of inputs, outputs, pipelines
  etc.

[ Attributes ]
  As   stated   before,   each   component   has   2   groups   of   attributes:
  a. common one, (general  one)  which  are  the  same  for  all  operators.
     port_a_size
     port_b_size
     port_a_sign
     port_b_sign
     clock_enable
     output_size
     pipeline

  b. unique one, which control unique behavior of the operation the component is providing

  [ Interface to attributes ]
    Is defined by 2 proc:
    * xco_get
    * xco_set

    These are defined in lib/xco_maps.tcl. 
    They guarantee access to all *.xco attributes.

    For subset (a) of attributes we need to define special mappings.
    This is because the naming of attributes for different operators varies:
    * add: port_a_size => port_a_width
           port_a_sign => port_a_type
    * mul: port_a_size => portawidth
           port_a_sign => portasign
    etc.
    Therefor procedures xco_get/xco_set are customized by xco_maps/xco_$name.tcl files.

    xco_get/xco_set first will try to find proper entry (mapping) from xco_maps/xco_$name.tcl
    and if not found it will try default mapppings defined within the procedures.
    In other words xco_maps/* files are layed out on top of default mappings.


[ Parsing  & Writing ]
  *.xco files are parsed with the help of lib/xco_parser.tcl.

  Example of parser looks like that:
    source lib/xco_parser.tcl
    source lib/xco_maps.tcl
    set fid [ open "my.xco" r ]
    set buf [ read $fid ]
    close $fid
    # this will read all attr into CSET and SET namespaces
    eval $buf
    # access to attr
    puts [ xco_get port_a_size ]


[ Meaning of attr ]
  pipeline = how many cycles from input to output
  = 0    => combinatorial 
  > 0    => sequential => we have clk,rst,ce signals
  latency  = how often inputs can be valid (operator reuse)

  In "general mapper" latency = pipeline, this should be customized in each
  operator mapper.
