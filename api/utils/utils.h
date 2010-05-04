#ifndef _UTILS_H_
#define _UTILS_H_

#include <cassert>
#include <iostream>
#include <sstream>
#include <fstream>


using namespace std;

namespace utils {
 bool fileExists(std::string filename);
 int str2int(std::string);
 std::string int2str(int i);
 std::string char2str(const char *s);
 void makeComment(std::string *);
} // namespace

#endif
