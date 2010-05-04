#include "getOperator.h"

/* ************************************************************************
 *                         Public methods
 * ************************************************************************ */
void getOperator::setDatabase(std::string dbname) {
  sql_ = new SQLITE3(dbname.c_str());
}


Operator *getOperator::select_by_rowid(int rowid) {

  std::string sql_query = "Select * from port where p_c_key = " + int2str(rowid);
  fetch_table_(sql_query, vport_, vport_nrow_, vport_ncol_);
  DLog("found rows: " << vport_nrow_);
  DLog("found cols: " << vport_ncol_);
  DLog("size: " << vport_.size());

  sql_query = "Select c_properties.* from c_properties, circuit where \
    circuit.cir_cp_key = c_properties.cp_key and circuit.cir_key = " + int2str(rowid);
  fetch_table_(sql_query, vcp_, vcp_nrow_, vcp_ncol_);
  DLog("found rows: " << vcp_nrow_);
  DLog("found cols: " << vcp_ncol_);
  DLog("size: " << vcp_.size());

  sql_query = "Select * from circuit where cir_key = " + int2str(rowid);
  fetch_table_(sql_query, vcir_, vcir_nrow_, vcir_ncol_);
  DLog("found rows: " << vcir_nrow_);
  DLog("found cols: " << vcir_ncol_);
  DLog("size: " << vcir_.size());


 
  // that's how we access the data f
  // std::cout << "p_name:  " << getPort(1)[db::p_name] << std::endl;
  // std::cout << "p_name:  " << getPort(2,db::p_name) << std::endl;

  Operator *o = new Operator();
  o->setName(vcir_[db::cir_entity_name]);

  // add ports
  for (int i=0; i<vport_nrow_; i++) {
    std::string name  = getPort(i)[db::p_name];
    int width     = str2int(getPort(i,db::p_width));
    bool isIn     = str2bool(getPort(i,db::p_isIn));
    bool isClk    = str2bool(getPort(i,db::p_isClk));
    bool isRst    = str2bool(getPort(i,db::p_isRst));
    bool isCE     = str2bool(getPort(i,db::p_isCE));
    bool isSigned = str2bool(getPort(i,db::p_isSigned));
    bool isUnsigned = str2bool(getPort(i,db::p_isUnsigned));
    bool isFP     = str2bool(getPort(i,db::p_isFP));
    int  exp_sz   = str2int(getPort(i,db::p_exp_sz));
    int  fra_sz   = str2int(getPort(i,db::p_fra_sz));
    bool isRegistered = str2bool(getPort(i,db::p_isRegistered));

    try {
      o->addPort(name, width, isIn, isClk, isRst, isCE, isSigned, 
        isUnsigned, isFP, exp_sz, fra_sz, isRegistered);
    } catch (std::string msg){
      std::cerr  << msg << endl;
    }
  }

  // when latency=0 set combinatorial = no rst & clock
  int latency = str2int(vcp_[db::cp_latency]);
  DLog(latency);
  DLog(vcp_[db::cp_key]);

  o->setPipelineDepth(latency);
  if (latency == 0) {
    o->setCombinatorial();
  } else {
    o->setSequential();
  }
  return o;
}

std::string getOperator::getPort(int port_id, db::port_t col) {
  int base = port_id * vport_ncol_;      // start index of selected port
  vector<std::string>::iterator it = vport_.begin() + base + col;
  return *it;
}

std::vector<std::string> getOperator::getPort(int port_id) {
  int base = port_id * vport_ncol_;      // start index of selected port

  vector<std::string>::iterator it = vport_.begin() + base;
  vector<std::string>::iterator ie = vport_.begin() + base + vport_ncol_;

  //  copy(it, ie, std::ostream_iterator<std::string>(std::cout,"\t"));
  return vector<std::string> (it,ie);
}

/* ************************************************************************
 *                         Private methods
 * ************************************************************************ */
void getOperator::fetch_table_(std::string sql_query, std::vector<std::string> &vres, int &nrow, int &ncol) {
  sql_->exe(sql_query);
  // DExec( sql_->print() ) ;

  if (sql_->nrow == 0) {
    std::cerr << "SQL query didn't gave any results" << endl;
    exit(1);
  }
  nrow = sql_->nrow;
  ncol = sql_->ncol;
  // vcol_head.

  // change size of result vector  
  vres.resize(sql_->vdata.size());

  vector<std::string>::iterator it = sql_->vdata.begin();
  vector<std::string>::iterator ie = sql_->vdata.end();
  copy(it, ie, vres.begin());
  // copy(it, ie, std::ostream_iterator<std::string>(std::cout,"\t"));
}

/* ************************************************************************ */
int getOperator::str2int(std::string s) {
      if (s.compare("") == 0 ) {
        std::cerr << "Converting NULL value to int" << std::endl;
        exit(1) ;
      }
      std::istringstream stream(s);
      int i;
      stream.operator>>(i);
      return i;
}
/* ************************************************************************ */
bool getOperator::str2bool(std::string s) {
      if (s.compare("") == 0 ) {
        std::cerr << "Converting NULL value to boolt" << std::endl;
        exit(1) ;
      }
      std::istringstream stream(s);
      bool b;
      stream.operator>>(b);
      return b;
}

/* ************************************************************************ */
std::string getOperator::int2str(int i) {
  stringstream out;
  out << i;
  return out.str();
}

