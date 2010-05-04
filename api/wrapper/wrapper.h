#ifndef _WRAPPER_H_
#define _WRAPPER_H_

#include <iostream>
#include <fstream>

#include "utils.h"
#include "getOperator.h"
#include "Signal.hpp"


/* TOP vhdl component (the one which wrappers other component) has to be
 * expressed as an class. Otherwise there is a problem with instanting the
 * components. */
class WRAPPER : public Operator {
  private:
  public:
    WRAPPER(Operator const &o, int regs_flag); 
};

#endif
