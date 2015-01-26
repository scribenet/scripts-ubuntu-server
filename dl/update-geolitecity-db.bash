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
remote_url="http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz"
local_path="/usr/share/geoip/lite-dbs/"
local_perm="775"
local_file="GeoIPCity.dat"
local_temp="/tmp/geolitecity-database-updater"

##
## Internal Config
##
SELF_SCRIPT_NAME="GeoIP Database Updater"
SELF_STEPS_TOTAL="5"
OUT_PROMPT_DEFAULT="y"

## Display welcome message
function out_welcome_custom {
    out_lines \
        "${SELF_SCRIPT_NAME}" \
        "" \
        "Handles downloading the latest GeoLiteCity database, uncompressing it," \
        "and moving it to a shared location using a filename PECL GeoIP understands."
}

## Display script usage and exit
function out_usage_custom {
    out_usage_optls "[-u | --remote-url" "[-d | --local-dir]" "[-f | --local-file]" "[-c | --set-chmod]" "[-h | --help]"

    out_usage_optdt 0 "-u" "--remote-url \"${remote_url}\""
    out_usage_optdd \
        "You can override the default download address with a custom URL of your choosing."
    out_usage_optdt 0 "-d" "--local-dir \"${local_path}\"/"
    out_usage_optdd \
        "You can override the default local directory path the download is moved to."
    out_usage_optdt 0 "-f" "--local-file \"${local_file}\""
    out_usage_optdd \
        "You can override the default local filename the download is renamed to."
    out_usage_optdt 0 "-c" "--set-chmod \"${local_perm}\""
    out_usage_optdd \
        "You can override the default local directory/file permissions using any
        valid format the chmod command accepts."
    out_usage_optdt 0 "-h" "--help"
    out_usage_optdd \
        "Display this help dialoge."
}

## Check for any variant of -h|--help|-help|--h and display program usage
if [[ $(echo "$@" | grep -E -e "\-?\-h(elp)?\b") ]];
then
    out_usage

## Otherwise parse any passed arguments
else
    # The last option that was read
    last_option=""

    # Loop through all passed arguments, ignoring any unknown
    for opt in "${@}";
    do
        if [[ "${opt}" == "-u" ]] || [[ "${opt}" == "--remote-url" ]]
        then
            last_option="remote-url"
            continue
        elif [[ "${opt}" == "-d" ]] || [[ "${opt}" == "--local-dir" ]]
        then
            last_option="local-dir"
            continue
        elif [[ "${opt}" == "-f" ]] || [[ "${opt}" == "--local-file" ]]
        then
            last_option="local-file"
            continue
        elif [[ "${opt}" == "-c" ]] || [[ "${opt}" == "--set-chmod" ]]
        then
            last_option="set-chmod"
            continue
        fi

        if [[ "${last_option}" == "remote-url" ]];
        then
            remote_url="${opt}"
            last_option=""
            continue
        elif [[ "${last_option}" == "local-dir" ]]
        then
            local_path="${opt}"
            last_option=""
            continue
        elif [[ "${last_option}" == "local-file" ]]
        then
            local_file="${opt}"
            last_option=""
            continue
        elif [[ "${last_option}" == "set-chmod" ]]
        then
            local_perm="${opt}"
            last_option=""
            continue
        fi
    done

fi

## Welcome message
out_welcome

## Check for required bins
check_bins_and_setup_abs_path_vars wget gunzip chmod mkdir mv basename sudo

## Get the remote filename and remove any possible get vars
remote_bs=${remote_url##*/}
remote_bs=${remote_bs%%\?*}
remote_ext=.${remote_url##*.}
remote_extracted_file=$(${bin_basename} ${remote_bs} ${remote_ext})

## Show runtime configuration setup
out_info_config \
    "Runtime Configuration:" \
    "" \
    "  Remote URL        -> ${remote_url}" \
    "  Remote Filename   -> ${remote_bs}" \
    "  Remote Extracted  -> ${remote_extracted_file}" \
    "  Local Path        -> ${local_path}" \
    "  Local Filename    -> ${local_file}" \
    "  Local Permissions -> ${local_perm}" \
    "" \
    "  Working Directory -> ${local_temp}"

## Allow the user to bail
out_prompt_boolean "0" "Would you like to continue?" "Confirm Config" "y"

## Create our temporary working directory
out_info \
    "Attempting to create/enter our temporary working directory:" \
    "  -> ${local_temp}"

${bin_mkdir} -p "${local_temp}" && cd "${local_temp}" || out_error \
    "Could not create temporary working directory."

## Download file
out_stage \
    "1" \
    "${SELF_STEPS_TOTAL}" \
    "Fetching Remote: ${remote_url}"

${bin_wget} -q "${remote_url}"

## Extract file
out_stage \
    "2" \
    "${SELF_STEPS_TOTAL}" \
    "Extracting file: ${remote_bs}"

${bin_gunzip} "${remote_bs}"

## Create local dirpath (if needed)
out_stage \
    "3" \
    "${SELF_STEPS_TOTAL}" \
    "Ensuring local dirpath exists: ${local_path}"

${bin_sudo} ${bin_mkdir} -p "${local_path}" || out_error \
    "Could not create local installation path for GeoIP file."

## Move new file in place
out_stage \
    "4" \
    "${SELF_STEPS_TOTAL}" \
    "Moving new file into place: ${remote_extracted_file} -> ${local_path}/${local_file}"

${bin_sudo} ${bin_mv} "${remote_extracted_file}" "${local_path}/${local_file}"

## Assigning permissions to local dir recursivly
out_stage \
    "5" \
    "${SELF_STEPS_TOTAL}" \
    "Assigning perms to local directory recursivly: ${local_perm}"

${bin_sudo} ${bin_chmod} -R ${local_perm} "${local_path}"

## Done
out_done \
    "Completed all operations!"

## EOF
