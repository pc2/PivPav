# TO enable debug:   cmake -DDEBUG=1
set(DB_FILENAME "${CMAKE_CURRENT_SOURCE_DIR}/ops.db")

project (SQLITE CXX)

message("# Creating Makefile for '${PROJECT_NAME}'")
cmake_minimum_required(VERSION 2.6)
 
cmake_policy(SET CMP0002 OLD)

include("${CMAKE_CURRENT_SOURCE_DIR}/../dir.conf")
include_directories(${DIR_UTILS})
include_directories(${DIR_COMMON})

#if (NOT DEFINED HAS_LIBUTILS) 
  SUBDIRS(${DIR_UTILS})
#endif (NOT DEFINED HAS_LIBUTILS) 

find_library(SQLITE3_LIB      NAMES sqlite3 )
#if (NOT DEFINED HAS_LIBSQL) 
  add_library(libsql                SHARED libsql)
  set_target_properties(libsql      PROPERTIES OUTPUT_NAME "sql")
  add_executable(test_sql       main)
  target_link_libraries(test_sql       libsql libutils ${SQLITE3_LIB})
  set(HAS_LIBSQL 1)
#endif (NOT DEFINED HAS_LIBSQL) 
