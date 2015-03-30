#!/bin/bash

##
## Scribe Inc
## Loop over btrfs filesystems and scrub 'em
##

## Gain self-awareness and common library
readonly SELF_DIRPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BOOTSTRAP_FILENAME="common-bootstrap.bash"
readonly BOOTSTRAP_FILEPATH="${SELF_DIRPATH}/../${BOOTSTRAP_FILENAME}"

## Include common bootstrap
source "${BOOTSTRAP_FILEPATH}"

##
## Internal Configuration
##
LOCK_FILE="/var/run/${0##*/}"
SELF_SCRIPT_NAME="Btrfs Scrub Mounts"
OUT_PROMPT_DEFAULT="y"

##
## Display welcome message
##
function out_welcome_custom 
{
    out_lines \
        "${SELF_SCRIPT_NAME}" \
        "" \
        "Performs a data scrub on all btrfs volumes."
}

##
## Check for any variant of -h|--help|-help|--h and display program usage
##
if [[ $(echo "$@" | grep -E -e "\-?\-h(elp)?\b") ]];
then
    out_usage
fi

##
## GO!
##

## Welcome message
out_welcome

## This script can only be run by root
if [[ $EUID -ne 0 ]]; then
   out_error "This script must be run as root. Try sudo."
   exit 1
fi

## Check for required bins
check_bins_and_setup_abs_path_vars btrfs shlock grep awk sort logger

## Make sure we aren't alreay running
if ! ${bin_shlock} -p $$ -f $LOCK_FILE; then
    echo "Lock file is held ($LOCK_FILE). It looks like this process is already running." >&2
    exit 1
fi

## Allow the user to bail
out_prompt_boolean "0" "This operation scrubs all disks and is fairly data intensive." "Continue?" "y"

## Foreach volume perform scrub
for volume in $(${bin_grep} '\<btrfs\>' /proc/mounts | ${bin_awk} '{ print $1 }' | ${bin_sort} -u)
do
    ## User Output
    out_info "Scrub started: ${volume}"
    ${bin_logger} "Scrub started: ${volume}"

    ${bin_btrfs} scrub start -Bd $volume

    ## User Output
    out_info "Scrub finished: ${volume}"
    logger "Scrub finished: ${volume}"
done

## Remove lock file
rm -fr ${LOCK_FILE}

## Done
out_done \
    "Completed all operations!"

## EOF

