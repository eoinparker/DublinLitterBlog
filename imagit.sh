#!/bin/bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

mout=$(md5 $*) 
lsout=$(ls -l $*)

echo $lsout $mout
IFS=$SAVEIFS
