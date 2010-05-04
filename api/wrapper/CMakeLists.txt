project (WRAPPER CXX)

message("# Creating Makefile for '${PROJECT_NAME}'")
cmake_minimum_required(VERSION 2.6)

include("${CMAKE_CURRENT_SOURCE_DIR}/../dir.conf")


include_directories(${DIR_UTILS})
include_directories(${DIR_HWWRITE})
include_directories(${DIR_SQL})
include_directories(${DIR_GETOPERATOR})

SUBDIRS(${DIR_UTILS})
SUBDIRS(${DIR_HWWRITE})
SUBDIRS(${DIR_SQL})
SUBDIRS(${DIR_GETOPERATOR})

find_library(SQLITE3_LIB      NAMES sqlite3 )

add_library(libwrapper            SHARED libwrapper)
set_target_properties(libwrapper  PROPERTIES OUTPUT_NAME "wrapper")
add_executable(wrapper            main)
target_link_libraries(wrapper     libwrapper libgetOperator libsql ${SQLITE3_LIB} libhw_write libutils)
