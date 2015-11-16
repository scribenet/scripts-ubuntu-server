#!/bin/bash

##
## Scribe Inc
## Download the latest BT blocklists.
##

## Gain self-awareness and common library
readonly SELF_DIRPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BOOTSTRAP_FILENAME="common-bootstrap.bash"
readonly BOOTSTRAP_FILEPATH="${SELF_DIRPATH}/../${BOOTSTRAP_FILENAME}"

## Include common bootstrap
source "${BOOTSTRAP_FILEPATH}"

##
## User configuration
##
BL_URL="https://www.iblocklist.com/lists.php"
BL_LEVELS="45" # Valid entries are numbers 1 through 5, one being the most strict, 5 being the least
WORKING_DIR="/tmp/${0##*/}"
FINAL_DIR="/www/scribenet-com_static/rmf/"
FINAL_FILE="bl.gz"

##
## Internal Configuration
##
LOCK_FILE="/var/run/${0##*/}"
SELF_SCRIPT_NAME="Blocklist Updater"
OUT_PROMPT_DEFAULT="y"
SELF_AUTHOR_NAME="Rob Frawley 2nd"
SELF_AUTHOR_EMAIL="code@scribe.software"
SELF_COPYRIGHT="No Copyright"
SELF_LICENSE="Public Domain"

##
## Display welcome message
##
function out_welcome_custom
{
    out_lines \
        "${SELF_SCRIPT_NAME}" \
        "" \
        "Downloads a collection of BT blocklists and zips them up into a single file that can" \
        "be consumed by a BT client." \
        "" \
        "Disclaimer:" \
        "  This script is not intended to aid in illegal use of BT to download copyrighted works," \
        "or in any way skirt the laws of your local jurisdiction. This script is provided with the" \
        "intend of blocking known bad peers and avoiding trojan viruses and other malicious content" \
        "from such connections. As such, it is intended to be imported into a BT client with the" \
        "understanding that said client will beused in a lawful manner." \
        "" \
        "Scribe is in no way responsible for misuse of this script by others. As it is licensed" \
        "under the 'Public Domain' it can be modified to provide a virtual 'dam' between a BT" \
        "user engaging in illicit acts and the authorities that monitor such transmissions. Such" \
        "is not endorsed, by Scribe or its employees, whom hold no control over the actions of" \
        "others." \
        "" \
        "Quite simply; please use this script responsibly."
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
check_bins_and_setup_abs_path_vars shlock curl grep sed xargs egrep gunzip cat

## Make sure we aren't alreay running
if ! ${bin_shlock} -p $$ -f $LOCK_FILE; then
    out_error "Lock file is held ($LOCK_FILE). It looks like this process is already running."
    exit 1
fi

## Show runtime configuration setup
out_info_config \
    "Runtime Configuration:" \
    "" \
    "  Working Dir          -> ${WORKING_DIR}" \
    "  Output Dir           -> ${FINAL_DIR}" \
    "  Output File          -> ${FINAL_FILE}" \
    "  Source Blocklist URL -> ${BL_URL}" \
    "  Blocklist Levels     -> ${BL_LEVELS}"

## Allow the user to bail
out_prompt_boolean \
    "0" \
    "Ready to download and (potentially) overwrite the current BT blocklist based on the above config." \
    "Continue?" "y"

out_stage \
    "1" \
    "5" \
    "Creating Working Dir and Downloading BL HTML"

## Create working directory
mkdir -p "${WORKING_DIR}" && cd "${WORKING_DIR}"

## Get HTML page to parse
curl -sL "${BL_URL}" -o blocklist-html.out

out_info "Downloaded temporary HTML to scrape for blocklist URLs to file 'blocklist-html.out'."

out_stage \
    "2" \
    "5" \
    "Confirming Valid HTML to Scrape"

COUNT=$(cat blocklist-html.out | egrep -A1 "star_[${BL_LEVELS}]" | egrep -o '[a-z]{20}' | sort -u | wc -l)

if [ "${COUNT}" == "0" ];
then
    out_error "Unable to find/parse any blocklist URLs from the provided URL (${BL_URL}) with the provided levels (${BL_LEVELS})."
    rm -fr ${LOCK_FILE}
    exit 1
fi

out_info "Found ${COUNT} blocklists based on provided criteria."

out_stage \
    "3" \
    "5" \
    "Downloading Each List and Passing to Compressor"

cat blocklist-html.out \
  | egrep -A1 "star_[${BL_LEVELS}]" \
  | egrep -o '[a-z]{20}' \
  | sort -u \
  | while read -r blocklist; \
    do \
      out_info "Fetching list: ${blocklist}."; \
      curl -sL "http://list.iblocklist.com/?list=${blocklist}&fileformat=p2p&archiveformat=gz" \
        | gunzip -q > list; \
    done \

out_stage \
    "4" \
    "5" \
    "Compressing full concatinated list into single file."

pigz_bin=$(which pigz)

if [ -n ${pigz_bin} ];
then
    out_info "Found 'pigz'! Using it to compress final output."
    pigz -11 list
else
    out_info "Could not find 'pigz' ;-(. Falling back to gzip."
    gzip list
fi

out_stage \
    "5" \
    "5" \
    "Moving final list to ${FINAL_DIR}/${FINAL_FILE} and cleaning up."

mv list.gz "${FINAL_DIR}/${FINAL_FILE}"

rm blocklist-html.out || true
cd ..
rm -fr "${WORKING_DIR}" || true

## Remove lock file
rm -fr ${LOCK_FILE}

## Done
out_done \
    "Completed all operations!"

## EOF
