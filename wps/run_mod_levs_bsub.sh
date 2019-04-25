#!/bin/bash
#
#BSUB -P NACD0008                      # Project 99999999
#BSUB -a poe                            # select poe
#BSUB -x                                # exclusive use of node (not_shared)
#BSUB -n 1                            # number of total (MPI) tasks
#BSUB -R "span[ptile=16]"               # run a max of 32 tasks per node
#BSUB -J mod_lev                           # job name
#BSUB -o mod_lev%J.out                     # output filename
#BSUB -e mod_lev%J.err                     # error filename
#BSUB -W 00:30                         # wallclock time
#BSUB -q special                        # queue: regular, premium, economy, small
#

count=0
for i in $( ls FILE:* ); do
 echo item: $i
 ./mod_levs.exe $i ${i}_mod
  mv ${i}_mod $i
done
