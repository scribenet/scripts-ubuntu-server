#!/bin/bash

##
## Scribe Inc
## Piwik log import wrapper script
##
## @author    Rob Frawley 2nd
## @copyright 2014 Scribe Inc.
## @license   MIT
##

## Gain self-awareness and common library
readonly SELF_DIRPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BOOTSTRAP_FILENAME="common-bootstrap.bash"
readonly BOOTSTRAP_FILEPATH="${SELF_DIRPATH}/../${BOOTSTRAP_FILENAME}"

## Include common bootstrap
source "${BOOTSTRAP_FILEPATH}"

##
## Configuration
##

## Piwik log import command config
piwik_reprocess_logs_after_import=0
piwik_url="https://piwik.scribe.systems/"
piwik_console_script_path="/www/scribe-systems_piwik/console"
piwik_console_script_opts="--force-all-websites --force-all-periods=315576000 --force-date-last-n=1000"
piwik_log_import_script_path="/www/scribe-systems_piwik/misc/log-analytics/import_logs.py"
piwik_log_import_script_opts="--recorders=10 --enable-http-errors --enable-http-redirects --enable-static --enable-bots --enable-reverse-dns --show-progress"

## Ionice/nice config
run_with_nice=1
run_with_nice_at=19
run_with_ionice=1
run_with_ionice_at=3

## Execution time limits
loop_max_seconds=3600

##
## Function definitions
##

## Display script usage and exit
function out_usage_custom
{
    #
    # Display script usage message
    #
    echo -en \
        "\nUsage:\n\t${SELF_FILENAME} site_id server_log [piwik_url]\n\n" \
        "\tsite_id\n" \
        "\t\tYou must provide a Piwik site ID which is passed to the import script and\n" \
        "\t\tdetermines what website your log file will apply to.\n" \
        "\n\tserver_log\n" \
        "\t\tYou must enter the absolute path to the nginx log file you want imported.\n" \
        "\n\tpiwik_url\n" \
        "\t\tYou may optionally overwrite the Piwik URL defined within this file. It is\n" \
        "\t\tpassed to the import script and is how the new log data is entered.\n" \
        "\n"
}


## Display welcome message
function out_welcome_custom
{
    out_lines \
        "Piwik Log Import Script" \
        "" \
        "This script handles importing a log file into Piwik using their command-line" \
        "client. As the commend-line tool often stops and errors out, we must wrap it" \
        "within this bash script, call it within a loop, and if the script bailed check" \
        "the log file for the --skip paramiter value we should apply and run it again." \
        "  This process may happen more than once, so the script will not exit until it" \
        "gets a zero return value from the Piwik import script OR the configured time" \
        "limit is reached (which should not happen, but has been added as a precausion" \
        "in the event that the script never succeeds, results in this bash wrapper script" \
        "in an unlimited while loop."
}

## Get pre commands (for ionice and/or nice)
function get_command_pre
{
    #
    # Build pre commans
    #
    local build_pre_command=""

    #
    # Configure ionice
    #
    if [[ ${run_with_ionice} -eq 1 ]]; then

        #
        # Get full path to ionice
        #
        check_bins_and_setup_abs_path_vars "ionice"

        #
        # Add it to pre_command
        #
        build_pre_command="${bin_ionice} -c${run_with_ionice_at} "

    fi

    #
    # Configure nice
    #
    if [[ ${run_with_nice} -eq 1 ]]; then

        #
        # Get full path to nice
        #
        check_bins_and_setup_abs_path_vars "nice"

        #
        # Add it to pre_command
        #
        build_pre_command="${build_pre_command}${bin_nice} -n${run_with_nice_at} "

    fi

    #
    # Echo the compiled final command for consumption into a variable
    #
    echo "${build_pre_command}"
}

## Get the Piwik log import full command
function get_command_piwik_log_import
{
    #
    # Echo the compiled final command for consumption into a variable
    #
    echo "${bin_python} ${piwik_log_import_script_path} ${piwik_log_import_script_opts} --output=${script_log} --url=${piwik_url} --idsite=${site_id} ${server_log}"
}

## Get the Piwik console process command
function get_command_piwik_archive
{
    #
    # Echo the compiled final command for consumption into a variable
    #
    echo "${bin_php} ${piwik_console_script_path} core:archive ${piwik_console_script_opts} --url=${piwik_url}"
}

## Determine the Piwik log import command's status
function get_piwik_log_import_status
{
    #
    # Check if --skip exists in logfile (suggesting we need to run it again)
    #
    local grep_return="$(${bin_grep} -oh "skip=[0-9]*" "${script_log}" > /dev/null; echo $?)"

    #
    # Use greps (sane - unlike piwiks log import script) return value to provide
    # a return value of our own (it will be the opposite of greps, the same return
    # value Piwik should return to begin with)
    #
    if [[ ${grep_return} -eq 0 ]]; then

        #
        # Value of 1 for error (grep found --skip in log)
        #
        echo 1

    else

        #
        # Value of 0 for success (grep did not find --skip in log)
        #
        echo 0

    fi
}

##
## Check provided parameters meet requirements
##

## Check for (required) first and second parameters
if [[ -z "${1}" ]] || [[ -z "${2}" ]]; then

    #
    # display usage and exit with non-zero value
    #
    out_usage
    exit 2

else

    #
    # define db user and password
    #
    site_id="${1}"
    server_log="${2}"

    #
    # Check the server logfile exists and is readable
    #
    if [[ ! -f "${server_log}" || ! -r "${server_log}" ]]; then

        #
        # Exit as the file doesn't exist or is not readble
        #
        out_error \
            "The provided server log filepath either does not exist or is not readable:" \
            "  -> Server Log : ${server_log}"

    fi

fi

## Check for (optional) third paramiter, piwik's URL
if [[ -n "${3}" ]]; then

    #
    # Use the cli provided Piwik URL
    #
    piwik_url="${3}"

fi

##
## Pre-flight checks
##
check_bins_and_setup_abs_path_vars "php" "python" "grep" "head" "tr" "tail" "date"

##
## Setup runtime variables
##

start_skip=0
start_time="$(${bin_date} +%s)"
script_log="/tmp/piwik-import_${start_time}_site-id-${site_id}.log"

##
## Welcome message!
##

out_welcome

#
# Let the user know what's up
#
out_info \
    "Runtime Configuration Variables" \
    "  -> Piwik URL     : ${piwik_url}" \
    "  -> Log File      : ${script_log}" \
    "  -> IO Nice       : ${run_with_ionice_at} $(if [[ ${run_with_ionice} -eq 0 ]]; then echo '[Disabled]'; else echo '[Enabled]'; fi)" \
    "  -> Nice          : ${run_with_nice_at} $(if [[ ${run_with_nice} -eq 0 ]]; then echo '[Disabled]'; else echo '[Enabled]'; fi)" \
    "  -> Max Loop Time : ${loop_max_seconds}" \
    "  -> Pre-Command   : $(get_command_pre)" \
    "  -> Script Path   : ${piwik_log_import_script_path}" \
    "  -> Script Opts   : ${piwik_log_import_script_opts}"

#
# Create our log file
#
touch "${script_log}"

##
## Start our "main" function loop.
## Continue calling piwik import script until it finishes successfully
##

while true ; do

    #
    # Check for start skip > 0
    #
    if [[ "${start_skip}" -gt "0" ]]; then

        #
        # Add --skip to piwik_log_import_script_opts variable
        #
        piwik_log_import_script_opts="${piwik_log_import_script_opts} --skip=${start_skip}"

    fi

    #
    # Run the command
    #
    out_info "Importing logs..."
    #$(get_command_pre) $(get_command_piwik_log_import) > "${script_log}" 2>&1
    $(get_command_pre) $(get_command_piwik_log_import)

    #
    # Determine if the script finished successfully
    # Since it doesn't seem to exit with a non-zero value on premature termination
    # we need to check for a "--skip" line in the log file using grep.
    #
    if [[ $(get_piwik_log_import_status) -ne 0 ]]; then

        #
        # Check that we have not exceeded out max loop execution time
        #
        if [[ $(${bin_date} +%s) -gt $((${start_time}+${loop_max_seconds})) ]]; then

            #
            # We've run for too long, exit with error
            #
            out_error \
                "The script was run for over the max loop time of ${loop_max_seconds} seconds." \
                "Please note that the Piwik import script did NOT finish successfully."

        fi

        #
        # Get skip-to point from log file
        #
        echo "DEBUG:START"
        tail -n 25 "${script_log}"
        echo "DEBUG:END"
        start_skip="$(${bin_grep} -oh "skip=[0-9]*" "${script_log}" | ${bin_head} -n1 | ${bin_tr} "=" "\n" | ${bin_tail} -n1)"

        #
        # Restarting import
        #
        out_notice "Previous run terminated prematurely. Restarting import at offset ${start_skip}."

    else

        #
        # Looks like everything is done so break the loop
        #
        break

    fi

done

##
## Display success message to user for log import
##

out_info "Log import complete."

##
## Handle the archive action if the user elected to do so
##
if [[ ${piwik_reprocess_logs_after_import} -eq 1 ]]; then

    #
    # Run the command
    #
    out_info "Reprocessing logs..."
    $(get_command_piwik_archive)
    out_info "Log reprocessing complete."

else

    #
    # Let the user know what they can do if they choose to reprocess the logs later
    #
    out_info \
        "To re-process these reports with your newly imported data, execute the following command:" \
        "  -> $(get_command_piwik_archive)" \
        "" \
        "To have this script perform this function automatically, set the following config value:" \
        "  -> piwik_reprocess_logs_after_import=1"

fi

##
## Exit as success
##

exit 0

## EOF
