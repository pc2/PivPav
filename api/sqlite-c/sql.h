#ifndef _SQL_H_
#define _SQL_H_

#include <iostream>
#include <cstdlib>
#include <string>
#include <vector>
#include <iterator>

#include <cassert>
#include <stdio.h>
#include <stdlib.h>
#include <sqlite3.h>

#include "db_schema.h"
#include "utils.h"
#include "debug.h"

class SQLITE3 {
private:
  sqlite3 *db;
  char *zErrMsg;
  char **result;
  int rc;
  int db_open;
public:
  int nrow,ncol;

  std::vector<std::string> vcol_head;
  std::vector<std::string> vdata;

  SQLITE3 (std::string);
  void print();
  int exe(std::string);
  ~SQLITE3();
};

#endif
