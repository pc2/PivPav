/* ====================================
 * Tests of getOperator library
 * ==================================== */

#include "getOperator.h"

using namespace std;

int main(int argc, char **argv){
  DLog( "Start." ) ;
  getOperator gop;
  gop.setDatabase(utils::char2str(DB_FILENAME));
//  Operator *o  = gop.select_by_name("add");
  Operator *t  = gop.select_by_rowid(1);
  t->outputVHDL(std::cout);
  DLog( "End." ) ;
  return 0;
}
