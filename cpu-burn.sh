#!/bin/bash

##
## Scribe Inc
## Start up CPU burn processes for each CPU core
##

#
# get the cpu count
#
CPU_COUNT="$(grep 'model name' /proc/cpuinfo | wc -l)"

#
# user info
#
echo "${0}: line 11: Starting ${CPU_COUNT} CPU burn processes"

#
# start burn processes for each core
#
for i in `seq 1 $CPU_COUNT`; do

  #
  # start one thread cpu-burn process in background
  #
  burnP6 &

  #
  # get the process id of the previously spawned process
  #
  burn_pid=$!

  #
  # let the user know whats happening...
  #
  echo "${0}: line 19: ${burn_pid} Started                 burnP6"

done

#
# wait for user to press enter
#
read -p "${0}: line 25: Press the [ENTER] key to stop CPU burn" READ_TMP

#
# stop all burn processes
#
killall burnP6

#
# all done...
#
echo "${0}: line 35: Stopped all burn processes"

#
# EOF
#
