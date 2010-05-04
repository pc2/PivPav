#!/bin/bash


# bl_file="$PWD/blacklist.txt"
comp_file="$PWD/completed.txt"
failed_file="$PWD/failed.txt"

if [ $# == 0 ] ; then
  echo "# Creates 2 files: $comp_file & $failed_file"
  echo "# $comp_file lists the numbers of the projects which were completed successfuly"
  echo "# $failed_file lists the numbers of the projectes which failed"
  echo ""
  echo "usage: $0 directory"
  exit
fi

# find all circuits which are completed
  rm -f $comp_file $failed_file

  cd $1
  ls -d * | sort -n | while read dir ; do
    succ_cnt=0
    for c in measure_balanced  measure_min_runtime  measure_power measure_timing_with_iob measure_timing_without_iob measure_timing_with_phys_synt ; do
      m_conf_file="$dir/$c/measure_db_store.txt"
      grep M_ISE_ERROR $m_conf_file 2>/dev/null | grep -q 0
      if [ $? == 0 ] ; then
        # echo "good design: $dir $c" | tee -a  $bl_file
        succ_cnt=$((succ_cnt+1))
      fi;
    done

    if [ $succ_cnt == 6 ] ;  then
      echo "# completed: $dir"
      echo $dir >> $comp_file
    else 
      echo $dir >> $failed_file
      # echo "# removing: $dir"
      # rm -rf $dir && sync
    fi
  done
