#!/bin/bash

##
## Scribe Inc.
## Generates a DER formatted file (for use as an OCSP staple) given a valid
## certificate chain bundle is passed. Checks the validity of each certificate
## in the chain with its respective OCSP server.
##
## @author  Rob Frawley 2nd
## @license MIT License
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

TEMP_DIRPATH="/tmp/ssl-generate-der-from-crt-bundle/"
SYSTEM_OPENSSL_ROOT_CERTIFICATES="/etc/ssl/certs/ca-certificates.crt"
#SYSTEM_OPENSSL_ROOT_CERTIFICATES="/System/Library/OpenSSL/certs/certs.pem"
DER_FILEEXT="der"
PERFORM_CERTIFICATE_EXTENDED_VERIFY=0
PERFORM_STAPLING_FILE_INSTALLATION=0
OUT_PROMPT_DEFAULT=""

##
## Internal Config
##

SELF_SCRIPT_NAME="SSL DER Generator (From Certificate Bundle File)"
CERT_BUNDLE_ABS_FILEPATH=0

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
        "This script generates a DER formatted file (generally, for use as an OCSP staple within" \
        "a webserver) given it is provided a valid certificate bundle file. Each certificate in" \
        "the bundle chain will be queried and validated against its OCSP server."
}

## Display script usage and exit
function out_usage_custom
{
    #
    # Display usage message test
    #
    out_usage_optls "[-h | --help]" "[-x | --extended-validation]" "[-i | --perform-install]" "absolute-path-to-cert-bundle"

    out_usage_optdt 0 "-x" "--extended-validation"
    out_usage_optdd \
        "When passed, it enables extended verification checks against the multiple extracted
        certiciates from within the bundled pem file provided. In addition to the OCSP checks
        that are handled by default, the extended checks perform per-certificate validation
        through the trust chain of them bundle."
    out_usage_optdd_p \
        "Each certificate is checked against their parent and children certificates, beginning
        with the low-level certificate (generally know as the root) working through any
        intermediary certificates, and finally checking the top-level certificate file. If any
        errors during this process occur, you will be provided the relivant details and given
        a chance to continue or stop the script at that point."
    out_usage_optdd_p \
        "Note that the behaviour of the check prompt that allows you to continue or stop can be
        overridden by the OUT_PROMPT_DEFAULT configuration variable."

    out_usage_optdt 0 "-i" "--perform-install"
    out_usage_optdd \
        "When passed, it enables automatic installation of the generated stapling file (.der file)
        within the same directory and with the same basename as the certificate bundle file passed
        to this script."
    out_usage_optdd_p \
        "It will perform a series of checks and actions to attempt to install the new file, as well
        as not clobber any pre-existing files, in the following order:"
    out_usage_optls_start
    out_usage_optls_i 1 \
        "If another file of the same name already exists at the path where the new file is to be
        placed during installation, the script will revert back to non-install mode."
    out_usage_optls_i 2 \
        "The file move will be attempted using the current user/group permissions that the script
        was originally called under."
    out_usage_optls_i 3 \
        "If the above fails, the script will attempt to use sudo to escalate privilages, allowing
        it to complete the file move. Prior to escalation, you will have the oportunity to cancel
        installation mode manually."
    out_usage_optls_end
    out_usage_optdd_p \
        "In the event that the script cannot perform the installation, it will still continue by
        reverting to non-installation mode."

    out_usage_optdt 1 "absolute-path-to-cert-bundle"
    out_usage_optdd \
        "This must be an **absolute** path to the file you would like this script to injest. This file
        must be a certificate bundle, containing a chain, or list, of certificates (pem/crt format)."
    out_usage_optdd_p \
        "Assuming the file is of a compatable format, this script will extract each individual certificate
        from the file and then perform a validity check to confirm it is not revoled using the OCSP
        server the certificate advertises."

    out_usage_optdt 0 "-h" "--help"
    out_usage_optdd \
        "Display this help dialoge."
}

#
# check for (required) first and second parameters
#
if [[ $# -lt 1 ]] || [[ "${1}" == "-h" ]] || [[ "${1}" == "--help" ]]; then

    #
    # display usage and exit with non-zero value
    #
    out_usage

else

    #
    # Set number of options
    #
    SET_OPTS=0

    #
    # Check that a valid path was passed
    #
    for opt in "$@"; do

        if [[ "${opt}" = /* ]] && [[ -f "${opt}" ]] && [[ -w "${opt}" ]]; then

            # path to the certificate bundle
            CERT_BUNDLE_ABS_FILEPATH="${opt}"
            SET_OPTS=$(( SET_OPTS + 1 ))

        fi

    done

    #
    # if no path was found, display error message and usage
    #
    if [[ "${CERT_BUNDLE_ABS_FILEPATH}" == "0" ]]; then
        out_usage "None of the arguments passed were absolute filepaths that were readable."
    fi

    #
    # Check for the optional -X (extended) parameter
    #
    if [[ "${1}" == "--extended-validation" ]] || [[ "${2}" == "--extended-validation" ]] || [[ "${3}" == "--extended-validation" ]] ||
       [[ "${1}" == "-x" ]] || [[ "${2}" == "-x" ]] || [[ "${3}" == "-x" ]]; then
        PERFORM_CERTIFICATE_EXTENDED_VERIFY=1
        SET_OPTS=$(( SET_OPTS + 1 ))
    fi

    #
    # Check for the optional -i (install stapling file) parameter
    #
    if [[ "${1}" == "--perform-install" ]] || [[ "${2}" == "--perform-install" ]] || [[ "${3}" == "--perform-install" ]] ||
       [[ "${1}" == "-i" ]] || [[ "${2}" == "-i" ]] || [[ "${3}" == "-i" ]]; then
        PERFORM_STAPLING_FILE_INSTALLATION=1
        SET_OPTS=$(( SET_OPTS + 1 ))
    fi

    #
    # Inform the user if they pass incorrect options
    #
    if [[ ! $# -eq $SET_OPTS ]]; then
        out_usage "You passed an invalid set of arguments. Please review the usage instructions."
    fi

fi

## Welcome message
out_welcome

## Check for require bins
check_bins_and_setup_abs_path_vars mkdir rm dirname basename rev cut cat awk openssl grep

##
## Additional Internal Configuration
##

DER_DIRPATH="$( ${bin_dirname} "${CERT_BUNDLE_ABS_FILEPATH}" )"
DER_BASENAME="$( ${bin_basename} "${CERT_BUNDLE_ABS_FILEPATH}" | ${bin_rev} | ${bin_cut} -d. -f2- | ${bin_rev} )"

## Show runtime configuration setup
out_info_config \
    "Runtime Configuration:" \
    "" \
    "  Temporary Wroking Dir -> ${TEMP_DIRPATH}" \
    "  System Root Certs     -> ${SYSTEM_OPENSSL_ROOT_CERTIFICATES}" \
    "  Certificate Bundle    -> ${CERT_BUNDLE_ABS_FILEPATH}" \
    "" \
    "  Certs Extended Verify -> $(if [[ ${PERFORM_CERTIFICATE_EXTENDED_VERIFY} -eq 0 ]]; then echo "NO"; else echo "YES"; fi)" \
    "  Attempt Installation  -> $(if [[ ${PERFORM_STAPLING_FILE_INSTALLATION} -eq 0 ]]; then echo "NO"; else echo "YES"; fi)" \
    "" \
    "  Output DER Dirpath    -> $(if [[ ${PERFORM_STAPLING_FILE_INSTALLATION} -eq 0 ]]; then echo "${TEMP_DIRPATH}"; else echo "${DER_DIRPATH}"; fi)" \
    "  Output DER Basename   -> ${DER_BASENAME}" \
    "  Output DER Extension  -> ${DER_FILEEXT}" \
    "  Output DER Pathname   -> $(if [[ ${PERFORM_STAPLING_FILE_INSTALLATION} -eq 0 ]]; then echo "${TEMP_DIRPATH}"; else echo "${DER_DIRPATH}"; fi)/${DER_BASENAME}.${DER_FILEEXT}"

## Allow the user to bail
out_prompt_boolean "0" "Would you like to continue?" "Confirm Config" "y"

## Begin step 1
out_stage \
    "1" \
    "6" \
    "Sanity Checks and Setup"

## Initialize temporary working directory
mkdir -p "${TEMP_DIRPATH}" && \
    cd "${TEMP_DIRPATH}" && \
    rm "${TEMP_DIRPATH}/"* > /dev/null 2>1

## Done with step 1
out_success "Step 1: Complete"

## Begin step 2
out_stage \
    "2" \
    "6" \
    "Analyzing Certificate Bundle"

# Parse pem file and output each cert in chain as own file
cat "${CERT_BUNDLE_ABS_FILEPATH}" | \
    awk -v c=-1 '/-----BEGIN CERTIFICATE-----/{inc=1;c++} inc {print > ("level-" c ".crt")} /---END CERTIFICATE-----/{inc=0}'

# determine number of extracted certs and define our ending index
SSL_CERT_COUNT="$(echo "$(ls -1 ./level-*.crt | wc -l) + 0" | bc)"
SSL_CERT_INDEX_END=$(( SSL_CERT_COUNT - 1 ))

# At a minimum we must have the public cert and a root cert (2 total)
if [[ "${SSL_CERT_COUNT}" -lt 2 ]]; then
    out_error \
        "The provided certificate bundle contains only a single certificate." \
        "Please provide a complete bundle (certificate chain), that includes your certificate" \
        "as well as any intermediate and root certificates."
fi

if [[ ! -f "${SYSTEM_OPENSSL_ROOT_CERTIFICATES}" ]]; then

    out_error \
        "The configured OpenSSL root certificates filepath does not exist:" \
        "  ${SYSTEM_OPENSSL_ROOT_CERTIFICATES}"

fi

# create bundle from certificates pulled out of pem file
cat ${SYSTEM_OPENSSL_ROOT_CERTIFICATES} > bundle.crt
cat level-[0-$INDEX].crt >> bundle.crt 2> /dev/null

## Done with step 2
out_success \
    "Step 2: Complete" \
    "  Certs Found -> ${SSL_CERT_COUNT}" \
    "  Within File -> ${CERT_BUNDLE_ABS_FILEPATH}"

# setup some variables
GENERIC_COMMAND_OUTPUT_FILE="command.out"
SSL_CERT_OCSP=""
SSL_CERT_OCSP_LAST=""
SSL_CERT_SERIAL=""
SSL_CERT_SERIAL_FIRST=""
SSL_CERT_I=1

# loop through our individual cert files
for level_filename in level-?.crt; do

    out_stage \
        "3.${SSL_CERT_I}" \
        "6" \
        "Analyzing Individual Certificate: ${level_filename}"

    SSL_CERT_SERIAL=$(${bin_openssl} x509 -serial -noout -in "${level_filename}")
    SSL_CERT_SERIAL="0x${SSL_CERT_SERIAL#*=}"

    if [[ "${SSL_CERT_I}" == 1 ]]; then
        SSL_CERT_SERIAL_FIRST="${SSL_CERT_SERIAL}"
    fi

    SSL_CERT_OCSP="$(${bin_openssl} x509 -noout -text -in "${level_filename}" | ${bin_grep} -oe "OCSP - URI:[^ ]*" | ${bin_cut} -d: -f2-)"
    if [[ -z "${SSL_CERT_OCSP}" ]]; then
        out_notice \
            "Step 3.${SSL_CERT_I}: Failed" \
            "  Cert File   -> ${level_filename}" \
            "  Cert Serial -> ${SSL_CERT_SERIAL}" \
            "  OCSP URL    -> Unknown" \
            "" \
            "It is likely you included the root certificate within the certificate bundle, which you shuld not do." \
            "While there are many other reasons that this error could occur, if this is the last certificate within" \
            "your file, it is likely the culpret."

        if [[ ${PERFORM_CERTIFICATE_EXTENDED_VERIFY} -eq 1 ]]; then
            ## Allow the user to bail
            out_prompt_boolean "1" "Would you like to continue creating the (likely invalid) DER file?" "Invalid Cert" "n"
        fi
    else
        out_success \
            "Step 3.${SSL_CERT_I}: Complete" \
            "  Cert File   -> ${level_filename}" \
            "  Cert Serial -> ${SSL_CERT_SERIAL}" \
            "  OCSP URL    -> ${SSL_CERT_OCSP}"

        SSL_CERT_OCSP_LAST="${SSL_CERT_OCSP}"
    fi

    let SSL_CERT_I+=1

done

out_stage \
    "4" \
    "6" \
    "Performing OCSP Validation On Entire Stack"

SSL_CERT_DER="${DER_BASENAME}.${DER_FILEEXT}"

${bin_openssl} ocsp -text -no_nonce \
    -issuer "level-1.crt" \
    -CAfile "bundle.crt" \
    -VAfile level-1.crt \
    -url "${SSL_CERT_OCSP_LAST}" \
    -serial "${SSL_CERT_SERIAL_FIRST}" \
    -respout "${SSL_CERT_DER}" > "${GENERIC_COMMAND_OUTPUT_FILE}" 2>&1

OCSP_RESPONSE_CHECK_1="$(grep "OCSP Response Status: successful" "${GENERIC_COMMAND_OUTPUT_FILE}" > /dev/null)"
OCSP_RESPONSE_CHECK_1_CODE="$?"
OCSP_RESPONSE_CHECK_2="$(grep "Cert Status: good" "${GENERIC_COMMAND_OUTPUT_FILE}" > /dev/null)"
OCSP_RESPONSE_CHECK_2_CODE="$?"
OCSP_RESPONSE_CHECK_3="$(grep "${SSL_CERT_SERIAL_FIRST}: good" "${GENERIC_COMMAND_OUTPUT_FILE}" > /dev/null)"
OCSP_RESPONSE_CHECK_3_CODE="$?"

if [[ "${OCSP_RESPONSE_CHECK_1_CODE}" == 0 ]] && [[ "${OCSP_RESPONSE_CHECK_2_CODE}" == 0 ]] && [[ "${OCSP_RESPONSE_CHECK_3_CODE}" == 0 ]]; then

    out_success \
        "Step 4: Complete" \
        "  Check 1 -> PASS" \
        "  Check 2 -> PASS" \
        "  Check 3 -> PASS"

else

    out_notice \
        "Step 4: Failed" \
        "  Check 1 -> $(if [[ "${OCSP_RESPONSE_CHECK_1_CODE}" == 0 ]]; then echo "PASS"; else echo "FAIL"; fi)" \
        "  Check 2 -> $(if [[ "${OCSP_RESPONSE_CHECK_2_CODE}" == 0 ]]; then echo "PASS"; else echo "FAIL"; fi)" \
        "  Check 3 -> $(if [[ "${OCSP_RESPONSE_CHECK_3_CODE}" == 0 ]]; then echo "PASS"; else echo "FAIL"; fi)"

    ## Allow the user to bail
    out_prompt_continue

fi

out_stage \
    "5" \
    "6" \
    "DER File Installation"

if [[ ${PERFORM_STAPLING_FILE_INSTALLATION} -eq 1 ]]; then

    out_info "Installing file automatically, per the user's request."

    mv "${SSL_CERT_DER}" "${DER_DIRPATH}/${DER_BASENAME}.${DER_FILEEXT}"

    out_success \
        "Step 5: Complete" \
        "  DER Output -> ${DER_DIRPATH}/${DER_BASENAME}.${DER_FILEEXT}"

else

    out_info "Not installing file automatically, per the user's request."

    out_success \
        "Step 5: Complete" \
        "  DER Output -> ${DER_DIRPATH}/${DER_BASENAME}.${DER_FILEEXT}"

fi

## Begin step 1
out_stage \
    "6" \
    "6" \
    "Temporary File Cleanup"

## Initialize temporary working directory
//rm *.crt > /dev/null 2>1
//rm *.out > /dev/null 2>1

## Done with step 1
out_success "Step 6: Complete"

## EOF
