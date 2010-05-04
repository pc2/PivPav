#include "wrapper.h"

using namespace std;

void usage(char *name) {
  std::cerr << name << " <-d filename> <-r > <-u filename> <-n value> <-x value> comp_name" << endl << \
    "\t -d        = database filename with operators" << endl << \
    "\t -r        = add registers - buffers" << endl << \
    "\t           = when combinatorial - inputs & outputs -> this creates sequential circuit" << endl << \
    "\t           = when sequential    - inputs" << endl << \
    "\t -u        = create ucf file (possible only for sequential circuit)" << endl << \
    "\t -n        = period for ucf file - corresponds to frequency of clock" << endl << \
    "\t -x        = row id from database (comp_name not necessary)" << endl << \
    "\t comp_name = component name from database"<< endl;
}

/* convert char to string */
std::string char2str(const char *s) {
  std::ostringstream out;
  out << s;
  return out.str();
}


void createUCF(std::string fname, std::string clk_name, std::string ns_val="10") {
  std::ofstream ucffile (fname.c_str());
  if (ucffile.is_open()) {
    ucffile << "NET \"" << clk_name << "\" TNM_NET = " << clk_name << ";" << endl;
    ucffile << "TIMESPEC TS_" << clk_name << " = PERIOD \"" << clk_name <<"\" " << ns_val << " ns;" << endl;
  } else {
    std::cerr << "Can't open ucffile for writing!";
    exit(1);
  }
  ucffile.close();
}


int main(int argc, char **argv){
  getOperator gop_;
  int opterr,c  = 0;
  int regs_flag= 0;
  int ucf_flag = 0;
  int ns_flag = 0;
  int db_flag = 0;
  int rowid_flag = 0;
  std::string dbname, ucfname, comp_name;
  std::string ns_val ("10"); // default value in nanoseconds for ucf file
  int rowid_val = 0;

  while ((c = getopt (argc, argv, "rd:u:n:x:")) != -1)
    switch (c)
    {
      case 'r':
        regs_flag = 1;
        break;
      case 'd':
        db_flag = 1;
        dbname = char2str(optarg);
        break;
      case 'u':
        ucf_flag = 1;
        ucfname = char2str(optarg);
        break;
      case 'n':
        ns_flag = 1;
        ns_val = char2str(optarg);
        break;
      case 'x':
        rowid_flag = 1;
        rowid_val = atoi(optarg);
        break;
      case '?':
        usage(argv[0]);
        return 1;
      default:
        abort ();
    }
  // assing comp_name
  if (optind < argc) {
    comp_name = argv[optind];
  // we do not need comp_name when rowid specified
  } else if (rowid_flag == 0) {
    usage(argv[0]);
    return 1;
  }
  // default filename for database
  if (dbname.size() == 0 ) dbname = "DB_FILENAME";

  // find component in database
  gop_.setDatabase(dbname);
  Operator *t;
  if (rowid_flag == 0) {
//    t = gop_.select_by_name(comp_name);
  } else {
    t = gop_.select_by_rowid(rowid_val);
  }

  // wrap component
  WRAPPER top(*t, regs_flag);
  top.setName(t->getName() + "_wrapper");

  if (ucf_flag == 1) 
    if (top.isSequential()) {
      if (ucfname.compare("") == 0) ucfname = top.getName() + ".ucf";
      createUCF(ucfname, top.getClkName(), ns_val);
    } else { 
      std::cerr << "Can't create ucf file for combinatorial operator" << endl;
      // exit(1);
    }

  top.outputVHDL(std::cout);
  return 0;
}

