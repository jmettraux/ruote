#!/bin/bash

# runs a test in a loop, until it fails
#
# the last argument can be an integer, the max number of tests.

echo $BASH_ARGV
COUNT=0

while [ 1 ]; do

  echo
  echo " *** $COUNT"
  ((COUNT=$COUNT + 1))
  #time ruby -I. $*
  time bundle exec ruby -I. $*

  if [[ "$?" != 0 ]]; then
    break
  fi
  if [[ "$COUNT" == $BASH_ARGV ]]; then
    break
  fi
done

