#!/bin/bash

# Flopoco does not come with the same settings as coregen.
# We encode the settings in filename.vhdl
# It means that filename has informations about sizes, latencies, dsp's etc.
#
# They can be later on easily read by any tool to figure out flopoco settings
# used to generate the circuit.

# Latency = 0 means that there is no clock signal in entity
# Latency = 1 means that there is a clock signal
# Both circuits are combinational.
# Latency > 1 means the sequential circuit

### THIS IS HOW IT WORKS
## 1. we use flopoco to generate various circuits
##    - the entity of circuit is fixed to QWERTY123 (check point 2).
##    - we use time command to measure the performance for each generation
##    - the filename of vhdl is changed to represent configuration
##    - we redirect stdout and stderr to file (logfile_tmp)
##    - this file is parsed to obtain pipeline stages
##    - .. and real cpu time (from time command)
##    - .. moreover 2nd line from top has command options which were used by flopoco

## 2. we use md5 to distinguish which circuits are duplicated
##   - we create file_sorted, file_unique
##   - this are compared
##   - finally rearrangment is done we create duplicates/ and unique/ directories

## 3. we are inserting unique/ files to database
##   - first we rearange files to directories
##     each *.vhdl gets seperate directory 
##     we move there *.vhdl *.log 
##   - we use ./addCustomCircuit.tcl script to generate db_api_file
##   - we append db_api_file with custom settings (from flopoco)
##   - we use ../db/insert.tcl script which reads db_api_file 
##     it puts whole circuit into db

## The problem with this script is that it uses bash
## When he would use tcl, then we could include parts of addCustomCircuit and Insert.tcl
## That would create much nicer script.

## This file should be rewritten in future to tcl.

function usage {
  echo "$0: exp_sz fra_sz size db"
  echo " exp_sz    - exponenta size"
  echo " fra_sz    - fraction size"
  echo " size      - when exp_sz & fra_sz are equal 0 then this param is used for integers"
  echo " db        - database filename"
  exit
}

# if [ $# != 4 ]; then 
#  usage
# fi



#### 0. CONFIGURATION
# create config for bash & read it
../_conf.tcl
source _conf.sh
rm _conf.sh


_CONFIG_db_file_full="$PWD/../test/test.db"

INT_TY="-int_signed"
EXP_SZ=11
FRA_SZ=52
SZ=$(( $EXP_SZ + $FRA_SZ +1 ))

rm -rf ${_CONFIG_gen_flo_dir_full}
mkdir -p "${_CONFIG_gen_flo_dir_full}/logs"

MAP2DB_CIRC["FPAdder"]="add"
MAP2DB_CIRC["IntAdder"]="add"
MAP2DB_CIRC["FPMultiplier"]="mul"
MAP2DB_CIRC["IntMultiplier"]="div"
MAP2DB_CIRC["FPDiv"]="div"


#### 1. generate set of circuits

for op in FPAdder FPMultiplier FPDiv IntMultiplier IntAdder
do
  for freq in 50 100 150 200 250 300 350 400; 
  do
    for dsp in yes no;
    do    
      for pipe in yes no;
      do
        # when float
        SZ_USE="$EXP_SZ $FRA_SZ"
        ISFP=1
        if [ $op == "IntAdder" ]; then
            SZ_USE="$SZ"
            EXP_SZ=0
            FRA_SZ=0
            ISFP=0
        fi;
        if [ $op == "IntMultipler" ] ; then
            SZ_USE="$SZ $SZ"
            EXP_SZ=0
            FRA_SZ=0
            ISFP=1
        fi;

        # execute
        logfile_tmp=`mktemp -p ${_CONFIG_gen_flo_dir_full}/logs XXXXX`

        CMD="$_CONFIG_gen_flo_bin_file -pipeline=${pipe} -DSP_blocks=${dsp} -frequency=${freq} -name=QWERTY123 ${op} ${SZ_USE}"
        echo "# ----  Generating circuit:" > $logfile_tmp
        echo "-pipeline=${pipe} -DSP_blocks=${dsp} -frequency=${freq} -name=${op} ${op} ${SZ_USE}" >> $logfile_tmp
        echo "" >> $logfile_tmp
        # execute
        (time ${CMD}) >> $logfile_tmp 2>&1 ; sync

        # parser results
        PIPE_LINE=`grep -i pipeline $logfile_tmp | grep -i depth | tail -1` 
        LATENCY=`echo $PIPE_LINE | awk '{printf $4}'`

        p=0;
        if [ $pipe == "yes" ] ; then 
          p=1 
        else 
          PIPE_LINE="   Pipelining disabled"
        fi

        d=0;
        if [ $dsp == "yes" ] ; then d=1 ; fi

        # there is always clock port in IntAdder - strange
        if [ $op == "IntAdder" ]; then
            LATENCY=1
        fi

        # when pipelining disable then latency = 0
        if [ -z $LATENCY ] ; then
          LATENCY=0
        fi;

        # status message
        echo "> circuit generated: $op ${SZ_USE} => $PIPE_LINE" 

        # change filename & move to dst dir
        # the filename contains configuration which is used when storing to db
        S_desc="fp${ISFP}_sz${SZ}_exp${EXP_SZ}_fra${FRA_SZ}"
        dstfile="${op}_${S_desc}_l${LATENCY}_f${freq}_dsp${d}_pipe${p}"
        mv flopoco.vhdl "${_CONFIG_gen_flo_dir_full}/$dstfile.vhdl"
        mv $logfile_tmp "${_CONFIG_gen_flo_dir_full}/$dstfile.log"
     done
    done
  done
done


#### 2. Use md5 to find which files are the same
cd $_CONFIG_gen_flo_dir_full

file_sorted=`mktemp .XXXXX`
file_uniq=`mktemp .XXXXX`
${_CONFIG_gen_flo_bin_md5_file} *.vhdl | awk '{print $1 "\t\t" $2}' | sort -n > $file_sorted
cat $file_sorted | awk '{print $1}' | uniq -c | sort -rn > $file_uniq

rm -rf uniq
mkdir uniq
cat $file_uniq | while read line ; do
  CNT=`echo $line | awk '{print $1}'`
  MD5=`echo $line | awk '{print $2}'`
  EX=`grep $MD5 $file_sorted | tail -1 | awk '{print $2}'`
  EX=${EX#(*}
  EX=${EX%*)}
  if [ $CNT == 1 ] ; then
    printf "This circuit is unique:  %s\n" $EX
  else 
    printf "There exists %4d duplicates for this  circuit: %s\n" $CNT $EX
  fi
  EX=${EX%%.vhdl}
  mv ${EX}.vhdl ${EX}.log  uniq
done

uniq_no=`wc -l $file_uniq | awk '{printf $1}'`
all_no=`wc -l $file_sorted | awk '{printf $1}'`
dup_no=$(( $all_no - $uniq_no ))
echo ""
echo "Overall there were generated: ${all_no} circuits"
echo "  uniq       = $uniq_no / $all_no"
echo "  duplicated = ${dup_no}/ $all_no"

rm $file_sorted $file_uniq

# reorder to 2 diff pools
rm -rf duplicates
mkdir duplicates
mv *.vhdl duplicates
mv *.log duplicates
rm -rf logs

# change entities to the same as file name
for dir in duplicates uniq; do
  save_pwd="$PWD"
  cd $dir
  ls *.vhdl | while read fname ; do
    entity=${fname%%.*}
    entity="${entity%%_*}"
    #echo $entity
    sed "s/QWERTY123/$entity/g" "$fname" > tmp && mv tmp $fname
  done
  cd $save_pwd
done


#### INSERT TO DATABASE ####
### 0. create dir for each file
### 1. restore configuration from the filename
### 2. use addCustomCircuit to generate -> db_api_file
### 3. append db_api_file with flopoco custom conf
### 4. insert data to db with db_api_file

cd uniq
ls *vhdl | while read line ; do

  # create prj_directory for the file
  file=`basename ${line%%.vhdl}`
  prj_dir="${PWD}/$file"
  vhdl_file="${prj_dir}/${file}.vhdl"
  log_file="${prj_dir}/stdout.log"
  db_api_file="${prj_dir}/${file}.db"

  # move files to prj dir
  mkdir -p $prj_dir
  mv "$line"         $vhdl_file
  mv "${file}.log"   $log_file

  
  # 1. parse the filename to restore confgiraution
  eval array=(`echo $line | tr '_' ' '`)
  FLO_TYPE="${array[0]}"
  ISFP="${array[1]/fp}"
  SZ="${array[2]/sz}"
  EXP_SZ="${array[3]/exp}"
  FRA_SZ="${array[4]/fra}"
  LATENCY="${array[5]/l}"
  FREQ="${array[6]/f}"
  DSP="${array[7]/dsp}"
  PIPE="${array[8]/pipe}"
  FLO_CMD_OPT=`head -2 $log_file | tail -1`
  CPU_TIME=`grep -i real $log_file | awk '{printf $2}' | sed 's#\([0-9]*\)m\([0-9\.]*\)s#\1*60 + \2#'`
  CPU_TIME=`echo $CPU_TIME | bc | xargs printf "%0.3f"`


  # 2. build command line options
  if [ $ISFP == 1 ] ; then
    opt="-fp_exp $EXP_SZ -fp_fra $FRA_SZ "
  else
    opt=" $INT_TY "
  fi
  TY=${MAP2DB_CIRC["$FLO_TYPE"]}

  # 2. create db_api_file
  rm -f $db_file
  cmd="${_CONFIG_add_cust_cir_file_full}  -type $TY -size $SZ -latency $LATENCY -no_db -db ${_CONFIG_db_file_full} ${opt} -db_api ${db_api_file} ${vhdl_file}"
  echo -e "\n$cmd" >> $log_file
  (time $cmd) >> $log_file 2>&1; sync
 

  # add specific generator information to db_file
  cat <<EOF >> $db_api_file

# -- informations for generator table --
_GF_KEY_PRJ $prj_dir
G_NAME      flopoco-0.11.0
G_IS_ERROR  0
G_CPU_TIME  $CPU_TIME
G_CMD_OPT   $FLO_CMD_OPT
EOF

#  insert into db
  echo "Inserting to db: $line"
  $_CONFIG_db_insert_cir_file_full $db_api_file 

done
