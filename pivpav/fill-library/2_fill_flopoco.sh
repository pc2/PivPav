#!/bin/bash

source ~/fpga-setup.sh
source libmanager.sh

# ===================================================== #
# Start single worker. Creates file with pid of that process.
# This is runned in background.
function start_worker() {

  function run_task () {
    local letter=$1
    # write mesg for manager & process stdout file 
    status_mesg="${status_line}[${letter}] ${params:1:200}"
    status_mesg="${status_line}[${letter}] ${params}"
    printf "\n$status_mesg\n"
    printf "\n\nSTART: `date`\n$status_mesg\n" >> ${WORKER_LOG_FILE_FULL}_${worker_id}

    # launch process with coregen (genop.tcl)
    ( eval $cmd ) 2>>${WORKER_ERROR_FILE_FULL} 1>>"${WORKER_LOG_FILE_FULL}_${worker_id}"
   if [ $? != 0 ] ; then 
          # when error happend during compilation
          echo "${status_line}[${letter}] error"
          echo "${status_mesg}" >> ${WORKER_ERROR_FILE_FULL}
          # release worker - mark it as unoccupied
          rm -f $lock_file && sync
          exit 1
    fi
    printf "END:  `date`\n\n\n" >> ${WORKER_LOG_FILE_FULL}_${worker_id}
  }


  local worker_id
  local bg_pid
  local lock_file
  local status_line
  local status_mesg
  local config_input
  local compile_dir
  local db_file
  local rowid

  get_first_id_of_unoccupied_worker
  worker_id=$?

  # get pid of this background process
  bg_pid=$!
  if [ -z $bg_pid ]; then 
     bg_pid=$$
  fi

  lock_file=${WORKER_RUNNING_FILE_FULL}_${worker_id}
  status_line=`printf "[w:%d|pid:%5d|line:%d/%d]" $worker_id $bg_pid $line_id $size`
  config_input=$*
  compile_dir="_compile/flopoco-$line_id"
  db_file=${DB_WORKER_FILE_FULL}_${worker_id}


  # mark worker as occupied (busy) 
  # save pid and other infos to the lock_file
  echo $status_line > $lock_file && sync

  save_pwd=$PWD
  cd ..

  # parse data from filename
  flo_file=`basename $config_input`
  eval array=(`echo $flo_file | tr '_' ' '`)
  flo_type=${array[0]}
  isFP=${array[1]/fp}
  sz=${array[2]/sz}
  exp_sz=${array[3]/exp}
  fra_sz=${array[4]/fra}
  latency=${array[5]/l}
  freq=${array[6]/f}
  dsp=${array[7]/dsp}

  # use addCircuit.tcl script
  params=" -db ${db_file} -type $flo_type -latency $latency -rate 1 -category flopoco"
  if [ $isFP -eq 1 ]; then
    params="$params -fp_exp $exp_sz -fp_fra $fra_sz"
  else 
    params="$params -int_signed"
  fi
  params="$params $config_input"
  cmd="./addCircuit.tcl $params" 
  run_task a 


  # use measure.tcl script
  rowid=`sqlite3 $db_file "SELECT max(op_key) from operator;" | awk '/^[0-9]+/ { print $1 }'`
  for goal in `./ise.tcl -list_goals`
    do
      params=" -n 20 -g $goal -d $db_file -w $compile_dir/measure -no_ngc $rowid"
      cmd="./measure.tcl $params"
      run_task m 
    done

  printf "END:  `date`\n\n\n" >> ${WORKER_LOG_FILE_FULL}_${worker_id}

  # printf "Remove dir: $compile_dir\n"
  rm -rf $compile_dir 

  cd $save_pwd

  # release worker - mark it as unoccupied
  rm -f $lock_file && sync
}

# ===================================================== #
function main ()
{
  # prepare configuration
  FILENAME=".flopoco-circuits-ls.txt"
  ls ${FLOPOCO_CIRCUITS_DIR_FULL}/*.vhdl > $FILENAME

  size=`wc -l $FILENAME | awk '{print $1}'`
  exec 3<$FILENAME # open fid

    line_id=1
    initialize_workers_status
    backup_workers_files
    while true ; 
    do
      launch_workers
      if [ $? -eq 1 ] ; then
        sleep 1
        echo ""
        echo "No more data in ${FILENAME}. Waiting till all workers will finish their work"
        wait_till_all_finish
        echo "Done."
        break
      fi;
      wait_till_some_unoccupied
    done

    exec 3>&-     # close fid
}

# ===================================================== #
main

