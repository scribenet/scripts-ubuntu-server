#!/bin/bash

##
## Scribe Inc
## Perform consistency check on /etc/passwd to /etc/shadow and /etc/group to /etc/gshadow
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
SELF_SCRIPT_NAME="System User/Group Checks"

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
        "\nUsage:\n\t${SELF_FILENAME} -v|-q|-h\n\n" \
        "\t-v" \
        "\tExecute command with verbose output handling.\n" \
        "\t-q" \
        "\tExecute command with verbose quiet handling.\n" \
        "\t-h" \
        "\tDisplay this message.\n" \
        "\n"
}

##
## Check provided parameters meet requirements
##

## Check for (required) first parameters
if [[ -z "${1}" ]] || [[ "${1}" == "-h" ]] || [[ $# -gt 1 ]]; then

    #
    # display usage and exit with non-zero value
    #
    out_usage
    exit 2

elif [[ "${1}" == "-q" ]]; then

    out_verbose=0
    command_opt="-q"

elif [[ "${1}" == "-v" ]]; then

    out_verbose=1
    command_opt=""

fi

## Welcome message
out_welcome

## Check for require bins
check_bins_and_setup_abs_path_vars pwck grpck

## Check passwd/shadow file using pwck
out_lines \
    "Checking passwd file"

out_empty_lines

${bin_pwck} ${command_opt} -r

out_empty_lines

if [[ $? -gt 0 ]]; then
    out_notice \
        "Errors were detected in passwd/shadow file." \
        "Please run the following to interactivly fix:" \
        "  -> ${bin_pwck}"
fi

## Check group/gshadow file using grpck
out_lines \
    "Checking group/gshadow file"

out_empty_lines

${bin_grpck} ${command_opt} -r

out_empty_lines

if [[ $? -gt 0 ]]; then
    out_notice \
        "Errors were detected in group/gshadow file." \
        "Please run the following to interactivly fix:" \
        "  -> ${bin_grpck}"
fi

## All done
out_lines \
    "Checks completed."

out_empty_lines

## Exit
exit 0

## EOF
