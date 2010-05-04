# Name of this file
CONFIG_FILE="_config.sh"

# IMPORTANT: numbers of workers / threads
WORKERS_NUMBER=14

# where to store files
WORKER_BACKUP_DIR="worker_logfiles.backup"
WORKER_RUNNING_FILE="worker_running"
WORKER_LOG_FILE="worker_stdout"
WORKER_ERROR_FILE="worker_error"

# where to store data
DATA_DIR="data"

# databases
DB_SCHEMA_SCRIPT_FILE="../db/create-schema.tcl"
DB_VIEW_SCRIPT_FILE="../db/data/create_view.sql"
DB_EMPTY_FILE="${DATA_DIR}/db_empty"
DB_WORKER_FILE="${DATA_DIR}/db"
DB_FINAL_FILE="${DATA_DIR}/final.db"

# coregen circuit generator configurations
GEN_CG_GENERATOR_FILE="../circuits/gen_coregen.tcl"
GEN_CG_VARIANTS_DIR="../circuits/gen_coregen/variants"
GEN_CG_INT_CONFIG_FILE="${DATA_DIR}/int_conf.txt"
GEN_CG_FP_CONFIG_FILE="${DATA_DIR}/fp_conf.txt"
GEN_CG_CONFIG_FILE="${DATA_DIR}/conf.txt"


# measurment
MEASURE_FILE="../measure.tcl"

# ise
ISE_FILE="../ise.tcl"

# directory with flopoco circuits
FLOPOCO_CIRCUITS_DIR="../circuits/gen_flopoco/uniq"
FLOPOCO_FNAME_PARSER="tools/flopoco-parse-fname.sh"

# ============================================== #
# DO NOT EDIT BELLOW
# ============================================== #

# this will remeber line number & it's used to stop parsing this file
STOP_PARSE=$LINENO

# ============================================== #
# Automatically create copies of vars with full path.
# It applies only to vars which in name have FILE or DIR keywoard.

# For example for this variable
# -> DB_WORKER_FILE=data/db
# It will create automatically such variable:
# -> DB_WORKER_FILE_FULL=/tmp/data/db
# ============================================== #

TMPFILE=`mktemp`
# open file descriptor (number 3) with this file
exec 3<$CONFIG_FILE
for ((i=1 ; i<$STOP_PARSE; i++)) 
  do
    if  read -u 3 line ; then
      echo $line | awk -F= '{if ($1 ~ /FILE|DIR/) print $1"_FULL=\"$PWD/$"$1"\""}' >> $TMPFILE
    else
      echo "Error when reading file $CONFIG_FILE , line number: $i"
      return 1
    fi
  done
# close fid
exec 3<&-

source $TMPFILE
rm -f $TMPFILE

#echo $DATA_DIR
#echo $DATA_DIR_FULL
#echo $DB_FINAL_FILE
#echo $DB_FINAL_FILE_FULL
