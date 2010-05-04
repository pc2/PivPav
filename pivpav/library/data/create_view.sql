DROP VIEW IF EXISTS d;
CREATE VIEW d AS 
 SELECT
  cir_key,
  cir_entity_name,
  cdt_name,
  cp_latency,
  cp_inputs_rate,
  measure.m_goal, 
  round(power.t_p,1),
  round( (1.0/timing.n_min_per)*1000, 1)  as "MHz after PAR",
  synthesis.n_ff,
  mapping.n_lut,
  mapping.n_slice,
  synthesis.n_io_buf,
  place_and_route.n_i_l,
  place_and_route.n_o_logic
 FROM 
   circuit,
   c_type,
   c_data_type, 
   c_properties,
   measure,
   power,
   timing,
   place_and_route,
   mapping,
   synthesis
 WHERE 
   m_c_key = cir_key and 
   cir_ct_key = ct_key and 
   cir_cdt_key = cdt_key and 
   cir_cp_key = cp_key and
   power.m_id = m_key and 
   timing.m_id = m_key and
   synthesis.m_id = m_key and
   mapping.m_id = m_key and
   place_and_route.m_id = m_key;

DROP VIEW IF EXISTS t1;
CREATE VIEW t1 AS
  SELECT * 
  FROM  d
  WHERE
  cir_key in (561,590,376,405,19,34,158,104,1161,1183,1115,1136,1011,691,661,675,1595,1209,630,627);
