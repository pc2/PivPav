#!/bin/bash

source _config.sh

if [ -d $DATA_DIR_FULL ] ; then
  echo "Cleaning ${DB_WORKER_FILE}_* files"
  echo rm -rf "${DB_WORKER_FILE_FULL}_*"
  rm -rf ${DB_WORKER_FILE_FULL}_*
fi

echo "Creating empty database: $DB_EMPTY_FILE"
$DB_SCHEMA_SCRIPT_FILE_FULL | sqlite3  $DB_EMPTY_FILE_FULL

echo "Creating database for each worker:"
for i in $(seq 0 $[$WORKERS_NUMBER -1 ])
do

  dst_file="${DB_WORKER_FILE}_${i}"
  echo " *  $dst_file"
  dst_file_full="${DB_WORKER_FILE_FULL}_${i}"
  cp $DB_EMPTY_FILE_FULL $dst_file_full
done
