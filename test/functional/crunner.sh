#!/bin/bash

TEST="test/functional/ct_0_concurrence.rb"
if [ $1 = "1" ]; then
  TEST="test/functional/ct_1_iterator.rb"
fi
if [ $1 = "2" ]; then
  TEST="test/functional/ct_2_cancel.rb"
fi

COUNT=0

while [ $? == 0 ]
do
  echo " *** $COUNT"
  ((COUNT=$COUNT + 1))
  echo "time ruby -I. $TEST $*"
  time ruby -I. $TEST $*
done

