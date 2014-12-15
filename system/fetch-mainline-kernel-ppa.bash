#!/bin/bash

##
## Scribe Inc
## Get the latest version of the mainline kernel based on the configured
## ppa url and optionally install
##

## Gain self-awareness and common library
readonly SELF_DIRPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BOOTSTRAP_FILENAME="common-bootstrap.bash"
readonly BOOTSTRAP_FILEPATH="${SELF_DIRPATH}/${BOOTSTRAP_FILENAME}"

## Include common bootstrap
source "${BOOTSTRAP_FILEPATH}"

##
## Configuration
##

SELF_SCRIPT_NAME="Disk Performance Metrics Generator"
NOW="$(date +%s)"
BONNIE_LOG_PATH="$(pwd)/.${SELF_SCRIPT}-${NOW}.log"
OPT_BONNIE=""
PATH_BONNIE=""
BONNIE_OUTPUT_BASE="/www/scribe-systems_benchmarks-boe/"
BONNIE_HTML_BASE="https://benchmarks.boe.scribe.systems/"
OUT_PROMPT_DEFAULT="y"

##
## Function definitions
##

## Display welcome message
function out_welcome_custom
{
    #
    # Display welcome message text
    #
    out_lines \
        "${SELF_SCRIPT_NAME}" \
        "" \
        "This script tests the performance of the provided folder and outputs an HTML metrics" \
        "page using bonnie++ and bon_cvs2html. Output directory of statistics is configurable" \
        "via the variable declarations at the beginning of this file."
}

## Display script usage and exit
function out_usage_custom
{
    #
    # Display usage message test
    #
    echo -en \
        "\nUsage:\n\t${SELF_FILENAME} directory_path [bonnie_opt_1 ... bonnie_opt_n]\n\n" \
        "\tdirectory_path\n" \
        "\t\tThe absolute path to the directory bonnie should run its tests within. The\n" \
        "\t\toutput metrics file will be posted to ${URL_METRICS_LIST}.\n" \
        "\n\t[bonnie_opt_1 bonnie_opt_n]\n" \
        "\t\tAll additional parameters are passed as options to bonnie++ directly.\n" \
        "\nExample:\n" \
        "\t${SELF_FILENAME} /path/to/folder -r 1000 -s 8192\n" \
        "\tThe above command will run bonnie tests within /path/to/folder and pass a RAM\n" \
        "\tsize of 1000MB and apply a specific file size for files used to determine metrics.\n" \
        "\n"
}

#
# check for (required) first and second parameters
#
if [[ -z "${1}" ]]; then

    #
    # display usage and exit with non-zero value
    #
    out_usage

else

    #
    # define bonnie testing directory path
    #
    PATH_BONNIE="${1}"

    #
    # Use any additional parameters as bonnie arguments
    #
    if [[ $# -gt 1 ]]; then

        OPT_BONNIE="${OPT_BONNIE} ${@:2} "

    fi

fi

## Welcome message
out_welcome

## Check for require bins
check_bins_and_setup_abs_path_vars cat tail bonnie++ stat tee bc mkdir bon_csv2html hostname tr rm touch

## Check that passed path exists and is readable/writable
if [[ ! -d "${PATH_BONNIE}" ]] || [[ ! -w "${PATH_BONNIE}" ]]; then

    out_error "Provided path does not exist or is not readable/writable by current user."

else

    cd "${PATH_BONNIE}"

fi

## Get some variables pertaining to the filesystem this folder is contained within
FILESYSTEM_HEX_ID="$(stat -f -c %i . 2> /dev/null)"
if [[ $? -ne 0 ]]; then
    FILESYSTEM_HEX_ID="unkn"
fi
FILESYSTEM_TYPE="$(stat -f -c %T . 2> /dev/null)"
if [[ $? -ne 0 ]]; then
    FILESYSTEM_TYPE="unkn"
fi
HOSTNAME="$(${bin_hostname})"

## Generate bonnie output name parameter
BONNIE_M_NAME="$(echo "${HOSTNAME}_${FILESYSTEM_TYPE}-${FILESYSTEM_HEX_ID}" | ${bin_tr} -cd '[[:alnum:]]._-')$(if [[ -n ${OPT_BONNIE} ]]; then echo " ($(echo "${OPT_BONNIE}" | sed -e 's/^ *//' -e 's/ *$//'))"; fi)"
BONNIE_OUT_NAME="$(echo "${HOSTNAME}_${FILESYSTEM_TYPE}-${FILESYSTEM_HEX_ID}" | ${bin_tr} -cd '[[:alnum:]]._-')_${NOW}.html"

## Configuration file used
out_info_config \
    "RUNTIME CONFIGURATION:" \
    "" \
    "  BIN_BONNIE       -> ${bin_bonnie}" \
    "  OPT_BONNIE       -> $(if [[ -z ${OPT_BONNIE} ]]; then echo "[None]"; else echo ${OPT_BONNIE}; fi)" \
    "" \
    "  BONNIE_LOG_PATH  -> ${BONNIE_LOG_PATH}" \
    "  BONNIE_M_NAME    -> ${BONNIE_M_NAME}" \
    "  BONNIE_HTML_BASE -> ${BONNIE_HTML_BASE}" \
    "  BONNIE_OUT_NAME  -> ${BONNIE_OUT_NAME}" \
    "" \
    "  DIRECTORY_PATH   -> ${PATH_BONNIE}" \
    "  FILESYSTEM_ID    -> ${FILESYSTEM_HEX_ID}" \
    "  FILESYSTEM_TYPE  -> ${FILESYSTEM_TYPE}"

out_prompt_continue

## Begin stage one: run bonnie
out_stage \
    "1" \
    "2" \
    "Run benchmark"
out_commands \
    "Running bonnie benchmark" \
    "${bin_bonnie} -d \"${PATH_BONNIE}\" ${OPT_BONNIE}2>&1 | ${bin_tee} \"${BONNIE_LOG_PATH}\""

## Calculate test execution time
UNIX_TIME_START=$(date +%s)

## Run bonnie++ command
${bin_bonnie} -d "${PATH_BONNIE}" ${OPT_BONNIE} 2>&1 | ${bin_tee} "${BONNIE_LOG_PATH}"

if [[ $? -ne 0 ]]; then
    out_empty_lines &&
        out_empty_lines &&
        out_error \
            "An unknown error occured during execution of ${bin_bonnie}. Exiting..." \
            "Check the log file for additional info: ${BONNIE_LOG_PATH}"
fi

## End of of timer
UNIX_TIME_END=$(date +%s)
TIME_SECONDS=$((UNIX_TIME_END-UNIX_TIME_START))

## Completion of step 1
out_empty_lines &&
    out_success "Bonnie benchmark: Completed in ${TIME_SECONDS} seconds"

## Begin stage two: generate HTML
out_stage \
    "2" \
    "2" \
    "HTML Output"

## Calculate the final absolute HTML URL and make sure it exists
BONNIE_OUTPUT_ABSOLUTE="${BONNIE_OUTPUT_BASE}${BONNIE_OUT_NAME}"

## Output command list
out_commands \
    "Generating HTML and Cleaning Up" \
    "BONNIE_OUTPUT_ABSOLUTE=\"${BONNIE_OUTPUT_BASE}${BONNIE_OUT_NAME}\"" \
    "${bin_mkdir} -p \"${BONNIE_OUTPUT_BASE}\" 2> /dev/null" \
    "${bin_touch} \"${BONNIE_OUTPUT_ABSOLUTE}\" 2> /dev/null" \
    "${bin_cat} \"${BONNIE_LOG_PATH}\" | ${bin_tail} -n 1 | ${bin_bon_csv2html} > \"${BONNIE_OUTPUT_ABSOLUTE}\"" \
    "${bin_rm} -fr \"${BONNIE_LOG_PATH}\""

## Calculate test execution time
UNIX_TIME_START=$(date +%s)

## Make sure the destination folder exists it exists
${bin_mkdir} -p "${BONNIE_OUTPUT_BASE}" 2> /dev/null; MKDIR_RET=$?
${bin_touch} "${BONNIE_OUTPUT_ABSOLUTE}" 2> /dev/null; TOUCH_RET=$?

## Error if user cannot create directory or doesn't have write permissions to it
if [[ ${MKDIR_RET} -ne 0 ]] || [[ ${TOUCH_RET} -ne 0 ]]; then
    out_error \
        "An error occured while trying to create the HTML output directory. Please ensure" \
        "you have permissions to create it and/or write to it:" \
        "  Output Dir -> ${BONNIE_OUTPUT_BASE}"
fi

## Generate HTML and redirect to file
${bin_cat} "${BONNIE_LOG_PATH}" | ${bin_tail} -n 1 | ${bin_bon_csv2html} > "${BONNIE_OUTPUT_ABSOLUTE}"

## Cleanup: remove our intermediate log file
${bin_rm} -fr "${BONNIE_LOG_PATH}"

## End of of timer
UNIX_TIME_END=$(date +%s)
TIME_SECONDS=$((UNIX_TIME_END-UNIX_TIME_START))

## Completion of step 1
out_success "HTML Generation: Completed in ${TIME_SECONDS} seconds"

## All done!
out_info_final \
    "All operations completed!" \
    "" \
    "You can now access your results via the following direct link or by browsing the index" \
    "of all compiled results via the generic link:" \
    "" \
    "  Direct URL     -> ${BONNIE_HTML_BASE}${BONNIE_OUT_NAME}" \
    "  Browse All URL -> ${BONNIE_HTML_BASE}"

## EOF
