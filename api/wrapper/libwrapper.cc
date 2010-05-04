#include "wrapper.h"

// Operator uses copy ctor - Wrapper is an exact copy of &o
WRAPPER::WRAPPER(Operator const &o, int regs_flag=0) : Operator(o) {
    Operator *t = const_cast<Operator *>(&o);

    vhdl << endl << "-- wire: (*)entity input & output ports, with (*)signals" << endl;

    // first connect clock & reset & CE
    if (t->isSequential()) {
      std::string clk = t->getClkName();
      if (clk.size() != 0) {
        inPortMap(t, clk, clk);
      } else {
        std::cerr << "Error: component sequential but without clock signal" << endl;
        exit(1);
      }

      std::string rst = t->getRstName();
      if (rst.size() != 0) { inPortMap(t, rst, rst); } 

      std::string ce = t->getCEName();
      if (ce.size() != 0) { inPortMap(t, ce, ce); } 
    } else {
      // combinatorial + buffer inputs&outputs => sequential
      if (regs_flag == 1) {
        setSequential();
        addInput("Clk",1);
        setClk("Clk");
      }
    }

    // connect rest of the signals
    int size = t->getIOListSize();
    for (int i=0; i<size; i++ ) {
      Signal *s = t->getIOListSignal(i);
      // skip for clk, rst, ce
      if (s->isClk()) continue;
      // if (s->isRst()) continue;
      // if (s->isCE())  continue;

      std::string s_name = s->getName();
      // input ports
      if (s->type() == Signal::in) {
          std::string s_name_in = s_name + "_sig" ;
          vhdl << declare(s_name_in, s->width()) << " <=  " << s_name << ";" << endl;
          if (regs_flag) nextCycle(false);  // create registers for inputs
          inPortMap(t, s_name, s_name_in);

      // output ports
      } else if (s->type() == Signal::out) {
        std::string s_name_out = s_name + "_sig" ;
        outPortMap(t, s_name, s_name_out);
        if (regs_flag) {  // create registers for combinatorial operator otherwise just wire
          std::string wire_output = s_name + " <= " + s_name_out;
          if (t->isSequential()) {
            vhdl << wire_output << ";" << "\t -- not registered for sequential operator" << endl;
          } else {
            vhdl << wire_output << " when rising_edge(" << getClkName() <<");" << "\t -- register for combinatorial operator" << endl;
          }
        } else {
          vhdl << s_name << " <= " << s_name_out << ";" << endl;
        }
      }
    }

    // instantiate 
    vhdl << endl << "-- instantiate wrapped component" << endl;
    vhdl << instance(t,"u0");
    };
