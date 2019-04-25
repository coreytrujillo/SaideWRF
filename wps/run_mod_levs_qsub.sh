#!/bin/bash
#
#PBS -A NSAP0003
#PBS -l select=1:ncpus=1:mpiprocs=1
#PBS -N mod_lev
#PBS -j oe
#PBS -l walltime=0:30:00
#PBS -q regular
#

count=0
for i in $( ls FILE:* ); do
 echo item: $i
 ./mod_levs.exe $i ${i}_mod
  mv ${i}_mod $i
done
