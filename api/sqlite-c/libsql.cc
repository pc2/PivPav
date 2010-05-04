#include "sql.h"

SQLITE3::SQLITE3 (std::string dbname ): zErrMsg(0), rc(0),db_open(0) {
  DLog("DB: opening file: " << dbname);
  assert(utils::fileExists(dbname) && "Database file does not exists");

  rc = sqlite3_open(dbname.c_str(), &db);
  if( rc ){
    DLog("problem when connecting to database");
    fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
    sqlite3_close(db);
  }
  db_open=1;
  DLog("DB: opened");
}

int SQLITE3::exe(std::string s_exe) {
  DLog("DB: stmnt executing: " << s_exe);
  rc = sqlite3_get_table(
      db,              /* An open database */
      s_exe.c_str(),       /* SQL to be executed */
      &result,       /* Result written to a char *[]  that this points to */
      &nrow,             /* Number of result rows written here */
      &ncol,          /* Number of result columns written here */
      &zErrMsg          /* Error msg written here */
      );

  DLog("DB: results nrow = " << nrow << " ncol = " << ncol);
  if(vcol_head.size() > 0) {vcol_head.clear();}
  if(vdata.size()>0) {vdata.clear();}

  if( rc == SQLITE_OK ){
    for(int i=0; i < ncol; ++i)
      vcol_head.push_back(result[i]); /* First row heading */

    for(int i=0; i < ncol*nrow; ++i) 
      if (result[ncol+i]!=0) {
        vdata.push_back(result[ncol+i]);
      } else {
        vdata.push_back("0");
      }
  } 

  sqlite3_free_table(result);
  DLog("DB: stmnt executed");
  return rc;
}

void SQLITE3::print() {
  if( vcol_head.size() > 0 ) {
      std::cout << "Headings" << std::endl;
      copy(vcol_head.begin(),vcol_head.end(),std::ostream_iterator<std::string>(std::cout,"\t")); 
      std::cout << std::endl << std::endl;

      std::cout << "Data" << std::endl;
      copy(vdata.begin(),vdata.end(),std::ostream_iterator<std::string>(std::cout,"\t")); 
      std::cout << std::endl;
    }
}

SQLITE3::~SQLITE3() { 
  sqlite3_close(db); 
} 
