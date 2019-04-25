#!/bin/bash

count=0
for i in $( ls FILE:* ); do
 echo item: $i
 ./mod_levs.exe $i ${i}_mod
  mv ${i}_mod $i
done
