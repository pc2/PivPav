#!/bin/bash

ls *.tcl | while read fname ; do
  echo -n "$fname  "
  ./$fname | wc -l
done 
