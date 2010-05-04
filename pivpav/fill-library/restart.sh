#!/bin/bash

rm -rf data
rm -rf worker*
# rm -rf ../_db_circuits

./0_create_conf.sh
./1_create_dbs.sh
./2_fill_coregen.sh

