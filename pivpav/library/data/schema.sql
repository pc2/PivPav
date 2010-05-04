-- THIS SCHEMA DOES NOT MAKE USES OF FOREIGN KEY CONSTRAINS --
-- TODO: enable foreign keys constrains --


  CREATE TABLE device (
    d_key               INTEGER PRIMARY KEY,
    d_device            VARCHAR(20),
    d_family            VARCHAR(20),
    d_package           VARCHAR(20),
    d_speedgrade        VARCHAR(5)
  );


  -- the file when compressed can contain directories & many files.
  CREATE TABLE file(
    f_key          INTEGER PRIMARY KEY,
    f_store        BLOB,

    f_is_tgz        INTEGER ,      -- is it comporessed
    f_is_dir       INTEGER ,
    f_is_file      INTEGER ,

    -- logs
    f_is_stdout    INTEGER ,
    f_is_stderr    INTEGER ,

    -- attributes of file
    -- IMPORTANT:: suffix at the end
    -- this is used later for finding files
    f_has_vhdl       INTEGER ,      -- there is vhdl file
    f_has_vhd        INTEGER ,      -- there is vhd file
    f_has_ver        INTEGER ,      -- there is ver file
    f_has_ngc        INTEGER ,      -- there is ngc file 
    f_has_xco        INTEGER ,      -- it's XCO file

    f_has_prj    INTEGER ,      -- when it keeps whole ISE project with other files
    -- reports
    f_has_xst    INTEGER ,
    f_has_map    INTEGER ,
    f_has_par    INTEGER ,
    f_has_trc    INTEGER ,
    f_has_pwr    INTEGER
  );



  -- circuit generator like: coregen and flopoco
  CREATE TABLE generator(
    g_key           INTEGER PRIMARY KEY,
    g_d_key         INTEGER ,         -- for which device this circuit was generated
    g_f_key_prj     INTEGER ,         -- all project generator files (logfiles, compilation .. )
    g_name          VARCHAR(30),      -- generator name (coregen, flopoco)
    g_cmd_opt       VARCHAR(1000),     -- input command opt
    -- result
    g_is_error      INTEGER ,         -- when ended with error
    -- performance
    g_cpu_time      REAL    ,         -- time used to generate
    g_mem           REAL              -- memory used to generate
  );

  CREATE TABLE c_type(
    ct_key          INTEGER PRIMARY KEY,
    ct_name         VARCHAR(60),
    ct_group_name   VARCHAR(40),

    ct_arithmetic   INTEGER ,       -- arithmetic operation
    ct_a_isAdd      INTEGER ,
    ct_a_isSub      INTEGER ,
    ct_a_isDiv      INTEGER ,
    ct_a_isMul      INTEGER ,
    ct_a_isSqrt     INTEGER ,
    ct_a_isPow      INTEGER ,
    ct_a_isLog      INTEGER ,

    ct_binary       INTEGER ,       -- binary operation
    ct_b_isSrl      INTEGER ,
    ct_b_isSrr      INTEGER ,
    ct_b_isCustom   INTEGER ,

    ct_conversion   INTEGER ,       -- conversion operations
    ct_c_fl2int     INTEGER ,
    ct_c_int2fl     INTEGER ,

    -- others
    ct_cpu          INTEGER ,       
    ct_controller   INTEGER ,
    ct_eth          INTEGER ,
    ct_usb          INTEGER  
  );

  CREATE TABLE c_data_type(
    cdt_key        INTEGER PRIMARY KEY,
    cdt_name       VARCHAR(40),      -- fp_s, fp_d, int32, int16
    cdt_size       INTEGER ,         -- total bitsize of data bus
    cdt_isFP       INTEGER ,         -- in & out are floats
    cdt_fp_exp     INTEGER ,         -- exponenta size (single = 8 double = 11)
    cdt_fp_fra     INTEGER ,         -- fraction size  (single = 23 double = 52)

    cdt_isINT      INTEGER ,         -- in & out are ints
    cdt_i_sign     INTEGER ,         -- signed
    cdt_i_unsign   INTEGER ,         -- unsigned

    cdt_isBIT      INTEGER           -- bits
  );

  CREATE TABLE c_properties(
    cp_key              INTEGER PRIMARY KEY,
    cp_is_sequential    INTEGER ,     -- output depends on inputs and staememory
    cp_is_combinational INTEGER ,     -- output is pure function of inputs
    cp_latency          INTEGER ,     -- pipeline stages 
                                      --   0 = no clock in design
                                      --   1 = combinatorial - there is a clock
                                      --  >1 = sequential    - there is a clock
    cp_inputs_rate      INTEGER ,     -- valid inputs delay (0 = every clock) / c_rate / clocks_per_div
    cp_has_pads         INTEGER       -- does it include I/O pads
  );

  -- top entity ports of circuit
  CREATE TABLE port(
    p_key               INTEGER PRIMARY KEY,
    p_c_key             INTEGER ,      -- which circuit
    p_name              VARCHAR(40),   -- port name
    p_type              VARCHAR(20),   -- port type
    p_width             INTEGER ,
    p_isIn              INTEGER ,      -- 1 = input port to entity, 0 = output port
    p_isClk             INTEGER ,
    p_isRst             INTEGER ,
    p_isCE              INTEGER ,
    p_isSigned          INTEGER ,
    p_isUnsigned        INTEGER ,
    p_isFP              INTEGER ,
    p_exp_sz            INTEGER ,
    p_fra_sz            INTEGER ,
    p_isRegistered      INTEGER ,        -- buffered (synchronous)
    p_isConst           INTEGER ,        -- when it's a constant value
    p_value             VARCHAR(40)      -- store value when constant
  );

  CREATE TABLE circuit(
    cir_key                INTEGER PRIMARY KEY,
    cir_f_res_key          INTEGER ,       -- file.f_key circuit in form of vhdl or ngc file
    cir_f_db_key           INTEGER ,       -- file with all informations for parser (db_store.txt)
    cir_g_key              INTEGER ,       -- generator key, otherwise = this is a custom circuit
    cir_ct_key             INTEGER ,       -- type of circuit
    cir_cdt_key            INTEGER ,       -- data type 
    cir_cp_key             INTEGER ,       -- properties of circuit
    cir_entity_name        VARCHAR(40),    -- top entity name
    cir_entity_parser_error INTEGER        -- top entity parsing error 
  );


  -- we mark if the fpga cad algorithms had run and finished the job
  -- we do not mark here if they produced valid results
  -- it means that map process can be completed (m_ise_run_map_error = 0 ) but
  -- there will be timing constrains issues
  CREATE TABLE measure (
    m_key             INTEGER PRIMARY KEY,
    m_c_key            INTEGER ,          -- which circuit
    m_f_db_key        INTEGER ,          -- file with db api
    m_f_key            INTEGER ,          -- compressed whole measurment project

    -- settings
    m_goal            VARCHAR(30),       -- settings for FPGA CAD algorithms
    m_freq            REAL    ,

    -- command options
    m_cmd_opt         VARCHAR(1000),      -- input command opt
    m_wrapper_cmd_opt VARCHAR(1000),      -- input command for the wrapper tool
    m_extract_cmd_opt VARCHAR(1000),      -- input command for the wrapper tool
    m_ise_cmd_opt     VARCHAR(1000),

    -- measure tools errors
    m_dir_error       INTEGER ,
    m_wrapper_error   INTEGER ,
    m_extract_error   INTEGER ,
    m_ise_error       INTEGER ,

    -- measure perf timing
    m_dir_cpu_time      REAL,
    m_wrapper_cpu_time  REAL,
    m_extract_cpu_time  REAL,
    m_ise_cpu_time      REAL,

    -- ise  errors / status
    m_ise_dir_error                     INTEGER, 
    m_ise_prj_create_error              INTEGER,
    m_ise_prj_addfiles_error            INTEGER,
    m_ise_prj_reopen_error              INTEGER,
    m_ise_prj_properties_error          INTEGER,

    m_ise_run_check_syntax_error        INTEGER,
    m_ise_run_synthesize_xst_error      INTEGER,
    m_ise_run_translate_error           INTEGER,
    m_ise_run_map_error                 INTEGER,
    m_ise_run_place_route_error         INTEGER,
    m_ise_run_generate_power_data_error INTEGER,
    m_ise_run_error                     INTEGER,

    -- ise - perf time
    m_ise_dir_cpu_time                        REAL ,
    m_ise_prj_create_cpu_time                 REAL ,
    m_ise_prj_addfiles_cpu_time               REAL ,
    m_ise_prj_reopen_cpu_time                 REAL ,
    m_ise_prj_properties_cpu_time             REAL ,
    m_ise_prj_compile_cpu_time                REAL ,

    m_ise_run_check_syntax_cpu_time           REAL ,
    m_ise_run_synthesize_xst_cpu_time         REAL ,
    m_ise_run_translate_cpu_time              REAL ,
    m_ise_run_map_cpu_time                    REAL ,
    m_ise_run_place_route_cpu_time            REAL ,
    m_ise_run_generate_power_data_cpu_time    REAL 

  );
