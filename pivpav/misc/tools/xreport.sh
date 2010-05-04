#!/bin/bash

XREPORT_BIN="xreport"
XREPORT_PRJDIR="$PWD/x"
REPORT_BIN="$PWD/reports/report_top_summary.tcl"
XREPORT_TMPDIR="xrep_tmp"
MODULE_NAME="circuit"
XREPORT_OUTPUT="${MODULE_NAME}_summary.html"

# wait max 5 seconds for the results
function wait_for_results {
  for i in 1 2 3 4 5 ; do
    if [ -e "$XREPORT_OUTPUT" ] ; then
      printf "  * %-15s %s\n" "Generated:" $XREPORT_OUTPUT
      return 0
    fi
    sleep 1
  done
  printf "  * %-15s %s\n" "ERROR no:" $XREPORT_OUTPUT
  return 1
}

if [ $# == 0 ] ; then
  echo "# Creates generates xreports"
  echo ""
  echo "usage: $0 <-f> directory"
  echo " -f         : force"
  exit
fi

DIR=$1
FLAG_FORCE=0
if [ $# == 2 ] ; then
  FLAG_FORCE=1
  DIR=$2
fi

cd $DIR
SAVE_PWD=$PWD
 find . -maxdepth 1 -type d -o -type l | sed "/\.$/d"| sort -n | while read dir ; do
  for c in measure_balanced  measure_min_runtime  measure_power measure_timing_with_iob measure_timing_without_iob measure_timing_with_phys_synt ; do
    DSTDIR="$SAVE_PWD/$dir/$c/ise"
    if [ ! -d $DSTDIR ] ; then
      continue
    fi
    cd $DSTDIR

  if [ -s $XREPORT_OUTPUT ] ; then
    if [ $FLAG_FORCE == 0 ] ; then
      continue
    else 
      rm -f $XREPORT_OUTPUT
    fi
  fi

  # make a copy of the circuit and change filenames
      rm -rf $XREPORT_TMPDIR
      mkdir -p $XREPORT_TMPDIR
      top_name=`ls *.ngc`
      top_name=${top_name/.ngc/}
      ls -p | grep -v "/" | while read f ; do
        dstf=${f/$top_name/$MODULE_NAME}
        cp $f "$XREPORT_TMPDIR/$dstf"
      done

  # get summary report from the tool
      echo "> $dir"
      cd $XREPORT_TMPDIR
      cp -rf $XREPORT_PRJDIR/* ./
      bash -c "$XREPORT_BIN -ise xreports.ise > /dev/null &"
      wait_for_results
      ps | grep $XREPORT_BIN | grep -v ".sh" | awk '{printf $1}' | xargs kill -9 
      sync

  # move results and delete the xreport dir
    cp -f $XREPORT_OUTPUT ../
    sync
    cd ..
    rm -rf $XREPORT_TMPDIR

  # convert from html to txt
    if [ ! -s ${XREPORT_OUTPUT} ]  ; then
      echo " error: empty file ${XREPORT_OUTPUT}"      
    fi
    DST_FILE="${XREPORT_OUTPUT/.html/.txt}"
    links -dump 1 -dump-width 150 ${XREPORT_OUTPUT} > ${DST_FILE}
    printf "  * %-15s %s\n" "Converted to:" ${DST_FILE}

  # parse the logfile
    SRC_FILE=${DST_FILE}
#    DST_FILE="${DSTDIR}/ise/${XREPORT_OUTPUT%.*}.sh"
#    $REPORT_BIN ${SRC_FILE} > $DST_FILE
#    source $DST_FILE
#    printf "  * %-15s %s\n" "Status:" "$errors"
#   exit

  done
done
