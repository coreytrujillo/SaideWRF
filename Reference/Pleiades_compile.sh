#!/bin/sh

#PBS -N compile_run
#PBS -l select=1:ncpus=2:model=san
#PBS -l site=static_broadwell
#PBS -m abe -M corey.trujillo@colorado.edu
#PBS -q normal
#PBS -j oe

# Configure WRF and WPS before runnin this!

date > compilerun.log
pwd >> compilerun.log
source Reference/Pleiades_EnvVars.sh

cd WRF/
./compile em_real > compile.log

cd ../
date >> compilerun.log
echo "WRF compiled!" >> compilerun.log

cd wps/
./compile

cd ../                                                                                                                                                                                                    date >> compilerun.log                                                                                                                                                                                    echo "WPS compiled!" >> compilerun.log

cd ../WRF
./compile emi_conv > emcompile.log

cd ../                                                                                                                                                                                                    date >> compilerun.log                                                                                                                                                                                    echo "convert_emis compiled!" >> compilerun.log


