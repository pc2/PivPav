[ intro ]
  reports are scripts which parse different logfiles and are searching for interesting
  values. They generate "reports". 
  Scripts can produce reports to the screen in the form of list or to the database (-s). 
  In the second case ./schema.tcl script is used to generate proper schema of
  the database.

  Configuration is done by providing $config variable.
  $config variable is an list. 
  * First value of the list is an regexp. This will be matched to logfile.
  * Second value is an name of the variable which will kept the value.
  - the name of the variable is used to generate column in database.
  - the name of vars is builded from acronyms (see [variable names]).
 
  Configuration is checked in sequential order. It means that second regexp
  will be tried only when first one has been positively matched.


[ files ]
  * utils.tcl    = common function
  * report.tcl   = this file is sourced by all reports. It providers general facilities
  * report_*.tcl = custom reports, which provide $config 


[ variable names ]
  n = number
  l = logic
  i = input    i_l = input logic
  o = output 
  e = external 
  t = time
  f = flag
  s = set
  b = before   t_b_clk
  a = after    t_a_clk


  ef = effort
  io = input output
  ff = flip flop

  lev = level
  off = offset
  clk = clock
  avg 
  min
  max 
  pin
  pwr = power
  red = reduction
  per = period
  err = error
  buf = buffer
  rel = related
  loc = locked
  mem = memory
  real = real   t_real
  cpu = cpu     t_cpu
  par = place and route (process)
  opt = optimization

  conn = connection

  hier = hierarchy    (keep_hier)
  freq = frequency
  proc = % procent
  best

  worst
  unrel = unrelated (logic)

  constr = contrains

  route   (routing)
  setup   (setup times)
  hold    (hold times)

  delay 

  placer (process)
  router (process)
  tgan = timing analayzer (process)
