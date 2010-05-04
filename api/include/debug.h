#ifndef _DEBUG_H
#define _DEBUG_H

#ifndef NDEBUG
#define DLog(msg)  std::cerr << \
   "DEBUG: " << __FILE__ << "[" << __LINE__ << ":" << \
   __FUNCTION__ << "]: " << msg << std::endl
#define DExec(expr) expr

#else
#define DLog(msg) 
#define DExec(expr) 
#endif

#endif
