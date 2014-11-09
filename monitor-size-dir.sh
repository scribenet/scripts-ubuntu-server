#!/bin/bash

##
## Scribe Inc
## Monitor directory size at specified intervals
##

#
# check for (required) first parameter
#
if [[ -z "${1}" ]]; then

  #
  # display usage and exit with non-zero value
  #
  echo -e "Usage:\n\t${0} /path/to/a/directory [sleep]"
  exit 1

else

  #
  # check if the directory does not exist
  #
  if [[ ! -e "${1}" ]]; then

    #
    # display error message and exit with non-zero value
    #
    echo "The passed directory does not exist!"
    exit 1

  fi

  #
  # define the directory path
  #
  dir_path="${1}"

fi

#
# check for optional sleep (seconds) value
#
if [[ -z "${2}" ]]; then

  #
  # if not specified, default to 4 seconds
  #
  sleep_secs="4"

else

  #
  # otherwise use the user-defined sleep value
  #
  sleep_secs="${2}"

fi

#
# initiate transferred array
#
start_time_unix="$(date +%s)"
start_size_kb="$(du --max-depth=0 $dir_path | cut -f1)"

#
# avoid division by 0 errors...
#
sleep 1

#
# loop forever...
#
while [ true ]; do

  #
  # get the current time and directory size (human readable)
  #
  now_size="$(du -h --max-depth=0 $dir_path | grep -o '\([0-9.]*[A-Z]\)')"
  now_time="$(date +'%s')"

  #
  # get the current directory size in kb and add to transfer_log
  #
  now_size_kb="$(du --max-depth=0 $dir_path | cut -f1)"
  transfer_diff_kb="$(expr ${now_size_kb} - ${start_size_kb})"
  time_unix_diff="$(expr ${now_time} - ${start_time_unix})"
  transfer_per_second_kb="$(expr ${transfer_diff_kb} / ${time_unix_diff})"
  transfer_per_second="$(expr ${transfer_per_second_kb} / 1024)"
  transfer_diff="$(expr ${transfer_diff_kb} / 1024)"

  #
  # echo time, path, and directory size
  #
  echo -en "\033[1;30m[ $(basename ${0}) ${now_time} ] "
  echo -en "\033[1;37m\t${dir_path}: "
  echo -en "\033[1;31m${now_size} "
  echo -en "\033[0;34m\tTotal Transfered: \033[1;34m~${transfer_diff}mb\033[0;34m\tAverage Speed: \033[1;34m~${transfer_per_second}mb/s\033[0;34m\n"

  #
  # sleep for specified seconds
  #
  sleep "${sleep_secs}"

done

#
# EOF
#
