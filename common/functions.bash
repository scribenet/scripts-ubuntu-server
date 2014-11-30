#!/bin/bash

##
## Scribe Inc
## Collections of helper functions and default variables for our bash scripts
##
## @author Rob Frawley 2nd <rmf@scribe.tools>
##

##
## Output functions
##

## Output passed arguments as lines
function out_lines
{
    #
    # For each line provided...
    #
    for line in "${@}"; do

        #
        # Output line with our formatting
        #
        echo -en "${OUT_PRE}${line}\n"

    done
}

## Display error message and exit
function out_error
{
    #
    # Set window text color
    #
    $bin_tput bold
    $bin_tput setaf 1

    #
    # Output message
    #
    echo -en "${OUT_PRE}\n${OUT_PRE}Critical Error:\n${OUT_PRE}\n"
    out_lines "${@}"
    echo -en "${OUT_PRE}\n\n"

    #
    # Reset window color
    #
    $bin_tput sgr0

    #
    # Exit script on error with non-zero return
    #
    exit 1
}

## Display notice/warning message
function out_notice
{
    #
    # Set window text color
    #
    $bin_tput bold
    $bin_tput setaf 3

    #
    # Output message
    #
    echo -en "${OUT_PRE}\n${OUT_PRE}Notice:\n${OUT_PRE}\n"
    out_lines "${@}"
    echo -en "${OUT_PRE}\n\n"

    #
    # Reset window color
    #
    $bin_tput sgr0
}

## Display info messages
function out_info
{
    #
    # Set window text color
    #
    $bin_tput setaf 7

    #
    # Output message
    #
    out_lines "${@}"
    echo -en "\n"

    #
    # Reset window color
    #
    $bin_tput sgr0
}

## Display script usage (generic) and exit
function out_usage_generic
{
    #
    # Display script usage message
    #
    echo -en \
        "\n" \
        "Usage:\n\t${SELF_FILENAME}\n" \
        "\n"
}

## Display script usage, using specific function if defined or generic function if not
function out_usage
{
    #
    # Check for specific function definition
    #
    if [[ "$(test_exit_code type -t out_usage_custom)" == "0" ]]; then
        out_usage_custom
    else
        out_usage_generic
    fi

    #
    # Exit with non-zero return
    #
    exit 2
}

## Display welcome message
function out_welcome_generic
{
    #
    # Output message
    #
    out_lines \
        "${SELF_SCRIPT_NAME}" \
        "" \
        "Author    : ${SELF_AUTHOR_NAME} <${SELF_AUTHOR_EMAIL}>" \
        "Copyright : ${SELF_COPYRIGHT}" \
        "License   : ${SELF_LICENSE}"
}

## Display welcome message
function out_welcome
{
    #
    # Set window text color
    #
    $bin_tput setaf 7

    #
    # Output pre-message
    #
    echo -en "\n${OUT_PRE}\n${OUT_PRE}\n"

    #
    # Check for specific function definition
    #
    if [[ "$(test_exit_code type -t out_welcome_custom)" == "0" ]]; then
        out_welcome_custom
        out_lines \
            "" \
            "Author    : ${SELF_AUTHOR_NAME} <${SELF_AUTHOR_EMAIL}>" \
            "Copyright : ${SELF_COPYRIGHT}" \
            "License   : ${SELF_LICENSE}"
    else
        out_welcome_generic
    fi

    #
    # Output post-message
    #
    echo -en "${OUT_PRE}\n${OUT_PRE}\n\n"

    #
    # Reset window color
    #
    $bin_tput sgr0
}

##
## General functions
##

## Test exit code of any function and echo 0 or 1
function test_exit_code
{
    #
    # Run command to test
    #
    "$@" > /dev/null 2>&1

    #
    # Get command's exit code
    #
    local status=$?

    #
    # Return result as 0 (success) or 1 (error)
    #
    if [[ $status -eq 0 ]]; then
        echo 0
    else
        echo 1
    fi
}

## Check for required binaries
function check_bins_and_setup_abs_path_vars
{
    #
    # For each binary name passed
    #
    for bin in "${@}"; do

        #
        # Attempt to find the binary path and create a variable that holds it
        #
        eval "bin_${bin}=$(which ${bin})"

        #
        # Check to make sure we were able to find the bin path
        #
        if [[ -z "$(which ${bin})" ]]; then

            #
            # Output error if bin path could not be found
            #
            out_error \
                "Could not find '${bin}' command but it is required." \
                "Please install it on your system or ensure it is within your PATH."

        fi

    done
}

##
## Setup variables
##

## Require tputs and setup variable to call it via absolute path
check_bins_and_setup_abs_path_vars tput

## Set name of script
SELF_FILENAME="$(basename ${0})"
SELF_SCRIPT_NAME="${SELF_FILENAME}"

## Set welcome message info
SELF_AUTHOR_NAME="Rob Frawley 2nd"
SELF_AUTHOR_EMAIL="rmf@scribe.tools"
SELF_COPYRIGHT="Scribe Inc."
SELF_LICENSE="MIT License"

## Output function configuration
OUT_PRE="# "

## EOF
