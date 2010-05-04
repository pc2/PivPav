project (getOperator CXX)

message("# Creating Makefile for '${PROJECT_NAME}'")
cmake_minimum_required(VERSION 2.6)

include("${CMAKE_CURRENT_SOURCE_DIR}/../dir.conf")


include_directories(${DIR_UTILS})
include_directories(${DIR_HWWRITE})
include_directories(${DIR_SQL})


SUBDIRS(${DIR_UTILS})
SUBDIRS(${DIR_HWWRITE})
SUBDIRS(${DIR_SQL})

find_library(SQLITE3_LIB      NAMES sqlite3 )


add_library(libgetOperator SHARED libgetOperator)
set_target_properties(libgetOperator      PROPERTIES OUTPUT_NAME "getOperator")
add_executable(test_getOperator main)
target_link_libraries(test_getOperator libgetOperator libsql libhw_write ${SQLITE3_LIB} libutils)
