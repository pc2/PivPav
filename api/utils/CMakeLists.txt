# TO enable debug:   cmake -DDEBUG=1
set(DB_FILENAME "${CMAKE_CURRENT_SOURCE_DIR}/ops.db")


project (UTILS CXX)

message("# Creating Makefile for '${PROJECT_NAME}'")
cmake_minimum_required(VERSION 2.4)

include("${CMAKE_CURRENT_SOURCE_DIR}/../dir.conf")

add_library(libutils                 SHARED libutils)
set_target_properties(libutils       PROPERTIES OUTPUT_NAME "utils")
add_executable(test_utils   main)
target_link_libraries(test_utils       libutils )
