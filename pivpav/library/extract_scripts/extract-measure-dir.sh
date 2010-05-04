#!/bin/bash

DBDIR="../fill-db/db/flo"
DSTDIR="d$1-$2-measure"

if [ $# -ne 2 ]; then
  echo "usage: $0 db_id rowid"
  exit
fi

DB_NAME="${BASH_SOURCE%/*}/${DBDIR}/db_${1}"
EXTRACT="${BASH_SOURCE%/*}/extract-files.tcl"
echo $DB_NAME
echo $EXTRACT


TMPDIR=`mktemp -d -p ./`

$EXTRACT -d ${DB_NAME} -C $TMPDIR -t measure -c projfiles $2 &&  sync
rm -rf ${DSTDIR} && sync 
mv $TMPDIR/* "${DSTDIR}" && sync
rm -rf ${TMPDIR} && sync
