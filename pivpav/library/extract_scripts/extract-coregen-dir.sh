#!/bin/bash

if [ $# -ne 2 ]; then
  echo "usage: $0 db_id rowid"
  exit
fi

DB_NAME="${BASH_SOURCE%/*}/../fill-db/data.fp/db_${1}"
EXTRACT="${BASH_SOURCE%/*}/extract-files.tcl"
echo $DB_NAME

TMPDIR=`mktemp -d -p ./`

./$EXTRACT -d ${DB_NAME} -C $TMPDIR -t operator -c projfiles $2
sync
mv $TMPDIR/* "$2-coregen"
rm -rf $TMPDIR
