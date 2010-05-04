#include "utils.h"

using namespace std;

bool utils::fileExists(std::string filename)
{
    ifstream ifile(filename.c_str());
    return ifile;
}


/* convert string to integer */
/* this does not work :( !!! */
int utils::str2int(std::string s) {
  std::istringstream stream(s);
  int i;
  stream.operator>>(i);
  return i;
}

/* convert integer to string */
std::string utils::int2str(int i) {
  stringstream out;
  out << i;
  return out.str();
}

/* convert char to string */
std::string utils::char2str(const char *c) {
  std::ostringstream out;
  out << c;
  return out.str();
}

/* puts -- on each line */
void utils::makeComment(std::string *str) {
    size_t pos = str->find('\n');
    while (pos != string::npos) {
      str->insert(pos+1, "-- ");
      pos = str->find('\n',pos+4);
    }
}
