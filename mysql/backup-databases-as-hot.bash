#!/bin/bash

##
## Scribe Inc
## Perform a hot-backup of MySQL data
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
db_user="${MYSQL_CONTROL_USER}"
db_pass="${MYSQL_CONTROL_PASS}"
db_host="localhost"
out_dir="$(pwd)"
enable_ionice=0
enable_nice=0
enable_redirection=1
opt_innobackupex="--no-lock --parallel=10 --throttle=600"
opt_ionice="-c2 -n7"
opt_nice="-n20"

##
## Internal Configuration
##
SELF_SCRIPT_NAME="MySQL Hot-Backup"
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
        "This script uses Percona Toolkit's innobackupex to perform an online (hot) backup of"\
        "a MySQL data directory. To configure innobackupex directectly, edit the config values"\
        "at the beginning of this script."
}

## Display script usage and exit
function out_usage_custom
{
    #
    # Display usage message test
    #
    out_usage_optls "[-u | --mysql-user]" "[-p | --mysql-pass]" "[-r | --show-raw-output]" "[-o | --out-dir]" "[--ionice]" "[--nice]" "[-h | --help]"

    out_usage_optdt 0 "-u user" "--mysql-user user"
    out_usage_optdd \
        "A MySQL user to use. The configured control dbuser will be used by default."
    out_usage_optdt 0 "-p pass" "--mysql-pass pass"
    out_usage_optdd \
        "A MySQL password to use. The configured control dbpass will be used by default."
    out_usage_optdt 0 "-r" "--show-raw-output"
    out_usage_optdd \
        "Show the raw output of innobackupex. All command output is redirected to /dev/null by default."
    out_usage_optdt 0 "-o \"/backup/path\"" "--out-dir \"/backup/path\""
    out_usage_optdd \
        "An output directory for the backup. The current directory is used by default."
    out_usage_optdt 0 "--use-nice"
    out_usage_optdd \
        "Enable nice. Uses the parameters ${opt_nice}."
    out_usage_optdt 0 "--use-ionice"
    out_usage_optdd \
        "Enable ionice. Uses the parameters ${opt_ionice}."
    out_usage_optdt 0 "--be-nice"
    out_usage_optdd \
        "Enable both nice and ionice."
    out_usage_optdt 0 "-h" "--help"
    out_usage_optdd \
        "Display this help dialoge."

}

#
# Check for (required) first and second parameters
#
if [[ $(echo "$@" | grep -E -e "\-?\-h(elp)?\b") ]]; then

    #
    # Display usage and exit with non-zero value
    #
    out_usage

else

    #
    # setup triggers for options
    #
    last_option=""

    #
    # Loop through any remaining options and apply them
    #
    for opt in "${@}"; do

        if [[ "${last_option}" == "mysql-user" ]]; then

            db_user="${opt}"
            last_option=""
            continue

        elif [[ "${last_option}" == "mysql-pass" ]]; then

            db_pass="${opt}"
            last_option=""
            continue

        elif [[ "${last_option}" == "out-dir" ]]; then

            out_dir="${opt}"
            last_option=""
            continue

        elif [[ "${opt}" == "-u" ]] || [[ "${opt}" == "--mysql-user" ]]; then

            last_option="mysql-user"
            continue

        elif [[ "${opt}" == "-p" ]] || [[ "${opt}" == "--mysql-pass" ]]; then

            last_option="mysql-pass"
            continue

        elif [[ "${opt}" == "-o" ]] || [[ "${opt}" == "--out-dir" ]]; then

            last_option="out-dir"
            continue

        elif [[ "${opt}" == "--use-nice" ]]; then

            enable_nice=1
            continue

        elif [[ "${opt}" == "--use-ionice" ]]; then

            enable_ionice=1
            continue

        elif [[ "${opt}" == "--be-nice" ]]; then

            enable_nice=1
            enable_ionice=1
            continue

        elif [[ "${opt}" == "-r" ]] || [[ "${opt}" == "--show-raw-output" ]]; then

            enable_redirection=0
            continue

        fi

    done

fi

## Welcome message
out_welcome

## Check for require bins
required_bins="innobackupex sed uname"
if [[ ${enable_nice} == 1 ]]; then required_bins="nice ${required_bins}"; fi
if [[ ${enable_ionice} == 1 ]]; then required_bins="ionice ${required_bins}"; fi
check_bins_and_setup_abs_path_vars $required_bins

## Edge case for Darwin
if [[ "$(${bin_uname} -s)" == "Darwin" ]]; then opt_ionice=""; fi

#
# directory path for backups
#
mbd="${out_dir}/"

## Show runtime configuration setup
out_info_config \
    "Runtime Configuration:" \
    "" \
    "  DB Username   -> ${db_user}" \
    "  DB Password   -> $(echo ${db_pass} | sed -r 's/(.{5}).*/\1*****/g')" \
    "  DB Hostname   -> ${db_host}" \
    "" \
    "  Output Dir    -> ${mbd}" \
    "" \
    "  Backup Params -> ${opt_innobackupex}" \
    "  Backup Output -> $(if [[ ${enable_redirection} -eq 1 ]]; then echo "Disabled"; else echo "Enabled"; fi)" \
    "  Nice          -> $(if [[ ${enable_nice} -eq 0 ]]; then echo "Disabled"; else echo "Enabled [${bin_nice} ${opt_nice}]"; fi)" \
    "  IoNice        -> $(if [[ ${enable_ionice} -eq 0 ]]; then echo "Disabled"; else echo "Enabled [${bin_ionice} ${opt_ionice}]"; fi)"

## Allow the user to bail
out_prompt_boolean "0" "Would you like to continue?" "Confirm Config" "y"

## Setup pre-command
pre_command=""
if [[ ${enable_nice} -eq 1 ]]; then pre_command="${bin_nice} ${opt_nice} "; fi
if [[ ${enable_ionice} -eq 1 ]]; then pre_command="${pre_command}${bin_ionice} ${opt_ionice} "; fi

## Prefix options with user and password
opt_innobackupex="--user=${db_user} --password=${db_pass} ${opt_innobackupex}"

out_notice \
    "Escalating privlages: ${pre_command}${bin_innobackupex} ${opt_innobackupex} ${mbd}"

out_stage \
    "1" \
    "1" \
    "Performing Backup (Be patient...)"

## Return value
RETURN=0

## DO IT!
if [[ ${enable_redirection} -eq 0 ]]; then

    sudo ${pre_command}${bin_innobackupex} ${opt_innobackupex} ${mbd}
    RETURN=$?

else

    sudo ${pre_command}${bin_innobackupex} ${opt_innobackupex} ${mbd} > /dev/null 2>&1
    RETURN=$?

fi

## Inform use of command return
if [[ ${RETURN} == 0 ]]; then

    out_done "Completed all operations!"

else

    out_error "Operations not completed!"

fi

#
# exit with command return
#
exit $RETURN

#
# EOF
#
