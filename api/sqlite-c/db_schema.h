#ifndef _DB_SCHEMA_H_
#define _DB_SCHEMA_H_

/* schema with sql tables */

/* this can be builded up automatically by build_system with cmd:
 * awk '$1 ~ /^cir_/  {printf $1",\n"} ' schema.sql 
 * awk '$1 ~ /^p_/  {printf $1",\n"} ' schema.sql */


namespace db {
enum cir_t {
    cir_key              ,
    cir_f_res_key        ,
    cir_f_db_key         ,
    cir_g_key            ,
    cir_ct_key           ,
    cir_cdt_key          ,
    cir_cp_key           ,
    cir_entity_name      ,
    cir_entity_parser_error ,
};


enum cp_t {
  cp_key                , 
  cp_is_sequential      ,
  cp_is_combinational   ,
  cp_latency            ,
  cp_inputs_rate        ,
  cp_has_pads           ,
};

enum port_t {
  p_key,
  p_ops_id,
  p_name,
  p_type,

  p_width,
  p_isIn,
  p_isClk,
  p_isRst,
  p_isCE,
  p_isSigned,
  p_isUnsigned,
  p_isFP,
  p_exp_sz,
  p_fra_sz,

  p_isRegistered,
  p_isConst,
  p_value,
};
};

#endif
