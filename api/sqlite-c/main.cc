#include "sql.h"

int main(int argc, char **argv){
  DLog("file:" <<  utils::char2str(DB_FILENAME));
  if( argc!=3 ){
   std::cerr << "Usage: " << argv[0] << " DATABASE SQL-STATEMENT" << std::endl;
   exit(1);
  }

  SQLITE3 sql(argv[1]);
  sql.exe(argv[2]);
  sql.print();

  return 0;
}

