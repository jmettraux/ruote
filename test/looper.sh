#!/bin/bash

# runs a test in a loop, until it fails

COUNT=0

while [ $? == 0 ]
do
  echo
  echo " *** $COUNT"
  ((COUNT=$COUNT + 1))
  time ruby -I. $*
done

