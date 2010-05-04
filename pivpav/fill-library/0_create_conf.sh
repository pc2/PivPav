#!/bin/bash

source _config.sh
save_pwd=$PWD

if [ ! -d ${DATA_DIR} ] ; then
  echo "Creating directory: ${DATA_DIR}/"
  mkdir ${DATA_DIR}
else
  for f in ${GEN_CG_INT_CONFIG_FILE} ${GEN_CG_FP_CONFIG_FILE}
    do
      echo "Removing file: $f"
      rm -rf $f
    done
fi


cd ${GEN_CG_VARIANTS_DIR_FULL}
echo "Creating int's conf: ${GEN_CG_INT_CONFIG_FILE}"
./int_variator.tcl > ${GEN_CG_INT_CONFIG_FILE_FULL}
echo "Creating fp's conf:  ${GEN_CG_FP_CONFIG_FILE}"
./fp_variator.tcl > ${GEN_CG_FP_CONFIG_FILE_FULL}

rm -f ${GEN_CG_CONFIG_FILE_FULL}
cat ${GEN_CG_INT_CONFIG_FILE_FULL} >> ${GEN_CG_CONFIG_FILE_FULL}
cat ${GEN_CG_FP_CONFIG_FILE_FULL} >> ${GEN_CG_CONFIG_FILE_FULL}

cd $save_pwd
