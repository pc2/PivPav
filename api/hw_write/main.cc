#include "Operator.hpp"
#include <iostream>

int main () {
  Operator *o = new Operator();
  o->setName("dupa");
//  o->setCombinatorial();
  o->addInput("X",32);
  o->addOutput("R",32);
  o->addPort("Clk",1,1,1,0,0,0,0,0,0,0,0);
  o->syncCycleFromSignal("R");
  o->nextCycle();
  o->outputVHDL(std::cout);
  std::cout << "ClkName = " << o->getClkName() << endl;
}
