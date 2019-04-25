#!/bin/bash

wrf_aaaa=$1
wrf_mm=$2
wrf_dd=$3
wrf_hh=$4
steps_fnl=$5

date_aux="${wrf_aaaa}-${wrf_mm}-${wrf_dd} ${wrf_hh}:00:00"

COUNTER=0
while [  $COUNTER -lt 10 ]; do
  echo The counter is $COUNTER
  let COUNTER=COUNTER+1 
done
