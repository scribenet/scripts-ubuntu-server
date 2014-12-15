#!/bin/bash

##
## Scribe Inc
## Imposer CPU usage limit on application
##

#
# check for (required) first parameter (the command)
#
if [[ -z "${1}" ]]; then

  #
  # display usage and exit with non-zero value
  #
  echo -e "Usage:\n\t${0} \"a-command -with params\" usagePercentLimit [cores-count-default-max-cpus]"
  exit 1

else

  COMMAND="${1}"

fi

#
# check for (optional) second parameter (cpu percent)
#
if [[ -z "${2}" ]]; then

  echo -e "Usage:\n\t${0} \"a-command -with params\" usagePercentLimit [cores-count:40]"
  exit 1

else

  IN_PERCENT="${2}"

fi

#
# check for (optional) second parameter (cpu count)
#
if [[ -z "${3}" ]]; then

  CPU_COUNT="$(cat /proc/cpuinfo | grep processor | wc -l)"

else

  CPU_COUNT="${3}"

fi
 
REQ_PERCENT=$(echo "${CPU_COUNT}*${IN_PERCENT}" | bc -l)
MAX_PERCENT=$((CPU_COUNT*100))

#
# do it
#
$COMMAND &
PROCESS_PID=${!}
cpulimit -p${PROCESS_PID} -l${REQ_PERCENT} -b > /dev/null 2>&1

echo "PID: ${PROCESS_PID}"

#
# EOF
#
