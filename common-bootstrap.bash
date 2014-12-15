#!/bin/bash

##
## Scribe Inc
## Include bash common files. This includes the checks file, config file,
## and functions definitions file.
##
## @author Rob Frawley 2nd <rmf@scribe.tools>
##

## Gain self awareness and include library files
readonly BOOTSTRAP_DIRPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BOOTSTRAP_LIB_DIRNAME="lib"
readonly BOOTSTRAP_LIB_DIRPATH="${BOOTSTRAP_DIRPATH}/${BOOTSTRAP_LIB_DIRNAME}"
readonly BOOTSTRAP_LIB_FILES=(
    "00_checks.bash"
    "01_config.bash"
    "02_functions.bash"
)

## Bootstrap error function
out_bootstrap_error()
{
    echo -e "\n$(echo 'Bootstrap Error' | tr '[:lower:]' '[:upper:]'): ${1}"

    for error_details_line in "${@:2}"
    do
        echo -e "  -> ${error_details_line}"
    done

    echo -e "\nExiting...\n"

    exit 4
}

## Check for bootstrap library directory
if [[ ! -d "${BOOTSTRAP_LIB_DIRPATH}" ]]
then
    out_bootstrap_error \
        "The required library directory cannot be found." \
        "Expected Path -> ${BOOTSTRAP_LIB_DIRPATH}" \
        "Expected Name -> ${BOOTSTRAP_LIB_DIRNAME}" \
        "Script Self   -> ${SELF_DIRPATH}"
fi

## Foreach files within library folder
for library_inc_file in "${BOOTSTRAP_LIB_DIRPATH}/"*".bash"
do
    if [[ ! -f "${library_inc_file}" || ! -r ${library_inc_file} ]]
    then
        out_bootstrap_error \
            "Could not find or load the required library file." \
            "Expected File -> ${library_inc_file}" \
            "Expected Name -> ${BOOTSTRAP_LIB_DIRNAME}" \
            "Script Self   -> ${SELF_DIRPATH}"
    else
        source "${library_inc_file}"
    fi
done

## EOF
