#!/bin/bash

# runs a test in a loop, until it fails
#
# the last argument can be an integer, the max number of tests.

COUNT=0
echo $BASH_ARGV

while [ $? == 0 ]
do

  echo
  echo " *** $COUNT"
  ((COUNT=$COUNT + 1))
  time ruby -I. $*

  if [[ "$COUNT" == $BASH_ARGV ]]; then
    break
  fi
done

