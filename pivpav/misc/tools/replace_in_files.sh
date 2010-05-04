#!/bin/bash

if [ $# != 2 ] ; then
  echo "Changes *.tcl files"
  echo "usage: $0 src_string dst_string"
  exit
fi

MASK="*.tcl"

echo "Changing: '$1' to '$2' in $MASK files"
echo ""

find . -type f -name "$MASK" | xargs grep $1 | awk -F: '{printf $1"\n"}' | while read fname; do
  echo $fname
  sed -i "s#$1#$2#g" $fname
done

