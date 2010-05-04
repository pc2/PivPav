#ifndef _GETOPERATOR_H_
#define _GETOPERATOR_H_

#include <vector>
#include <assert.h>
#include "debug.h"
#include "utils.h"
#include "hw_write.h"
#include "sql.h"


class getOperator
{
  private:
    SQLITE3 *sql_;
    std::string dbname_;
    std::vector<std::string> vport_, vcir_, vcp_;
    int vport_ncol_, vcir_ncol_, vcp_ncol_;
    int vport_nrow_, vcir_nrow_, vcp_nrow_;

    std::string int2str(int);
    int  str2int(std::string);
    bool str2bool(std::string);

    // get data from database
    void fetch_table_(std::string, std::vector<std::string> &, int &, int &);

    // accessors of data
    // std::vector<std::string> getOperator();
    std::vector<std::string> getPort(int);
    std::string getPort(int, db::port_t);

  public:
    void setDatabase(std::string);
    Operator *select_by_rowid(int rowid);

    // Operator *select_fastest(std::string);
    // Operator *select_smallest(std::string);
    // map created operator with structures keeping properties
};


#endif
