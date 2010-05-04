# TO enable debug:   cmake -DDEBUG=1

project (HW_WRITE CXX)

message("# Creating Makefile for '${PROJECT_NAME}'")
cmake_minimum_required(VERSION 2.6)


include("${CMAKE_CURRENT_SOURCE_DIR}/../dir.conf")

add_library(libhw_write                 SHARED Operator Signal)
set_target_properties(libhw_write       PROPERTIES OUTPUT_NAME "hw_write")
add_executable(test_hw_write    main)
target_link_libraries(test_hw_write     libhw_write)
set(HAS_LIBHWWRITE 1)
