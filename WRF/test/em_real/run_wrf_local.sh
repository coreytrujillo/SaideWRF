#!/bin/bash

# SCRIPT TO PERFORM A WRF RUN IN THE LOCAL DISK OF THE MACHINE

# FIRST CREATE THE FOLDER "WRF_run" IN YOUR USER ROOT IN THE LOCAL DISK
# RUN THIS SCRIPT INSIDE THE TEST/EM_REAL/ FOLDER AFTER RUNNING REAL.EXE

#SET BY USER
user="psaide"
path_local_hd="/glade/p/nacd0005/saide/ORACLES_forecast/WRF_v3.6.1_chem_tracer90_run2"
#path_local_hd="/scratch/pablo_share/seac4rs_forecast/WRF_v3.4.1_run1"
number_proc=8

#END OF USER SETTINGS

path_run=$PWD
cd $path_local_hd

echo $path_run

ln -s $path_run/* .

#mpdrun -np $number_proc ./wrf.exe

echo REMEMBER TO MOVE YOUR OUTPUT FILES!!!
