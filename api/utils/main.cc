#include "utils.h"

int main(int argc, char *argv[]) {

  std::string s("1234");
  int d  =  1234;

  //  conversion functions
  printf("string %5s = utils::int2str(%d)\n",  utils::int2str(d).c_str(), d);
  printf("string %5s = utils::int2str(%d)\n",  utils::int2str(d).c_str(), d);
  printf("string %5s = utils::char2str(%c)\n", utils::char2str("c").c_str(), 'c');

  std::string filename(utils::char2str(argv[0]));
  if (utils::fileExists(filename)) {
    std::cout << "File: '" << filename << "' exists\n";
  } else {
    std::cout << "File: '" << filename << "' does not exists\n";
  }

}
