#!/bin/bash

##
## Scribe Inc
## Get the latest GeoLiteCity datebase file
##

## Gain self-awareness and common library
readonly SELF_DIRPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BOOTSTRAP_FILENAME="common-bootstrap.bash"
readonly BOOTSTRAP_FILEPATH="${SELF_DIRPATH}/../${BOOTSTRAP_FILENAME}"

## Include common bootstrap
source "${BOOTSTRAP_FILEPATH}"

##
## User Configuration
##
btrfs_vols="/mnt/storage/ /mnt/main/ /mnt/volatile/ /mnt/web/"
btrfs_seq=55

##
## Internal Configuration
##
SELF_SCRIPT_NAME="Btrfs Filesystem Balance"
OUT_PROMPT_DEFAULT="y"

##
## Display welcome message
##
function out_welcome_custom 
{
    out_lines \
        "${SELF_SCRIPT_NAME}" \
        "" \
        "Performs an incremental balance on all volumes."
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
check_bins_and_setup_abs_path_vars btrfs wc seq

## Show runtime configuration setup
out_info_config \
    "Runtime Configuration:" \
    "" \
    "  Btrfs Path -> ${bin_btrfs}" \
    "  Volumes    -> ${btrfs_vols}" \
    "  Increments -> 1 to ${btrfs_seq}"

## Allow the user to bail
out_prompt_boolean "0" "Would you like to continue?" "Confirm Config" "y"

## Get final count of volumes to iterate over
btrfs_increments="$(${bin_seq} ${btrfs_seq})"
btrfs_vols_count="$(echo "${btrfs_vols}" | ${bin_wc} -w)"

## Set stage to 1
stage_i=1

## Foreach volume
for volume in ${btrfs_vols}
do
    ## User Output
    out_stage \
        "${stage_i}" \
        "${btrfs_vols_count}" \
        "Balancing: ${volume}"

    for btrfs_increment in ${btrfs_increments}
    do
        out_info \
            "Running: Filesystem balance on ${volume} with dusage of ${btrfs_increment}." \
            "Command: ${bin_btrfs} fi balance -dusage=${btrfs_increment} ${volume} > /dev/null 2>&1"

        ${bin_btrfs} fi balance start -dusage=${btrfs_increment} ${volume} > /dev/null 2>&1
    done

    ## Increment stage
    stage_i=$((stage_i + 1))

done

## Done
out_done \
    "Completed all operations!"

## EOF
