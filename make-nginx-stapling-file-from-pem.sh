#!/bin/bash

##
## Given a PEM file (containing an entire certificate chain for use with Nginx),
## check each step in the certificate chain using an OCSP server (as advertised
## by the certificate itself) to determine its validity and non-revocated status,
## and finally create a DER-formatted OCSP staple file for Nginx
##
## @author  Rob Frawley 2nd
## @license MIT License
## @version 0.5.0
##

#
# user-configurable variables
#

# temporary directory to work in while runing checks
DIR_PATH_TEMP_WORK="/tmp/.ssl-nginx-verify-and-staple"

# extension of pem files used (generally pem on *nix, crt on windows)
CERT_EXTENSION_PEM="pem"

# path to file/dir of system-installed root CAs (only one used depending on os)
OPENSSL_ROOT_CERTS=/etc/ssl/certs/ca-certificates.crt

# enable or disable extended certificate checks
SSL_EXTENDED_VERIFY=true

#
# collection of simple functions
#

# simple output errpr function
function out_error
{
    out_line "${1}" 1>&2 && exit 1
}

# simle title output function
function out_tine()
{
    out_line "${1}" 0 | tr '[:lower:]' '[:upper:]'
}

# simple output line function
function out_line()
{
    if [[ "$#" == 2 ]]; then
        indent_counter=0
        while [ $indent_counter -lt "${2}" ]; do
            echo -e "  \c"
            let indent_counter+=1
        done
    fi
    echo -e "${1}"
}

# simple output string function
function out_str()
{
    echo -e "${1}\c"
}

# output command usage information
function out_usage()
{
    out_line "Usage:\n\t./$(basename ${0}) absolute-pem-file-path"
}

#
# begin program
#

# define script version variable
SELF_VERSION="v0.1.0"

# user must pass a valid absolute path to the pem file to parse
if [[ -z "${1}" || "$#" != 1 ]]; then
    out_usage
    out_error "You must provide an absolute path to a PEM file as the only argument."
elif [[ ! -f "/${1}" ]]; then
    out_error "The requested PEM file does not exist: /${1}"
else
    FILE_PATH_PEM="${1}"
fi

# initialize temporary working directory
mkdir -p "${DIR_PATH_TEMP_WORK}" && cd "${DIR_PATH_TEMP_WORK}" && rm "${DIR_PATH_TEMP_WORK}/"* > /dev/null

# define basename for new bundle/staple file based on provided pem name
FILE_NAME_BASE="$(basename "${FILE_PATH_PEM}" | rev | cut -d. -f2- | rev )"

# output basic config
out_tine "CONFIG"
out_line "Script Version   : ${SELF_VERSION}" 1
out_line "Temporary Dir    : ${DIR_PATH_TEMP_WORK}" 1
out_line "Export File Base : ${FILE_NAME_BASE}" 1

# parse pem file and output each cert in chain as own file
cat "${FILE_PATH_PEM}" | \
    awk -v c=-1 '/-----BEGIN CERTIFICATE-----/{inc=1;c++} inc {print > ("level-" c ".crt")} /---END CERTIFICATE-----/{inc=0}'

# determine number of extracted certs and define our ending index
SSL_CERT_COUNT="$(echo "$(ls -1 ./level-*.crt | wc -l) + 0" | bc)"
SSL_CERT_INDEX_END="$(echo "$SSL_CERT_COUNT - 1" | bc)"

# at a minimum we must have the public cert and a root cert (2 total)
if [[ "${SSL_CERT_COUNT}" -lt 2 ]]; then
    out_error "Please provide a PEM file with a certificate chain, including the domain/public certificate as well as any
               intermediate and root certificates to continue."
fi

# output chain info
out_tine "ANALYZING PEM"
out_line "Filepath           : ${FILE_PATH_PEM}" 1
out_line "Certificates found : ${SSL_CERT_COUNT}" 1

# create bundle from certificates pulled out of pem file
cat ${OPENSSL_ROOT_CERTS} > bundle.crt
cat level-[0-$INDEX].crt >> bundle.crt 2> /dev/null

# output individual cert info
out_tine "CERTIFICATES"

# setup some variables
GENERIC_COMMAND_OUTPUT_FILE="command.out"
SSL_CERT_OCSP=""
SSL_CERT_OCSP_LAST=""
SSL_CERT_SERIAL=""
SSL_CERT_SERIAL_FIRST=""
SSL_CERT_I=1

# loop through our individual cert files
for level_filename in level-?.crt; do

    out_line "Certificate File ${SSL_CERT_I}" 1

    SSL_CERT_SERIAL=$(openssl x509 -serial -noout -in "${level_filename}")
    SSL_CERT_SERIAL="0x${SSL_CERT_SERIAL#*=}"

    if [[ "${SSL_CERT_I}" == 1 ]]; then
        SSL_CERT_SERIAL_FIRST="${SSL_CERT_SERIAL}"
    fi

    SSL_CERT_OCSP="$(openssl x509 -noout -text -in "${level_filename}" | grep -oe "OCSP - URI:[^ ]*" | cut -d: -f2-)"
    out_line "Filename : ${level_filename}" 2
    out_line "Serial   : ${SSL_CERT_SERIAL}" 2
    if [[ -z "${SSL_CERT_OCSP}" ]]; then
        out_line "OCSP URL : Unknown" 2
    else
        out_line "OCSP URL : ${SSL_CERT_OCSP}" 2
        SSL_CERT_OCSP_LAST="${SSL_CERT_OCSP}"
    fi

    let SSL_CERT_I+=1

done

SSL_CERT_DER="${FILE_NAME_BASE}.staple.der"

openssl ocsp -text -no_nonce \
    -issuer level-1.crt \
    -CAfile bundle.crt \
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

# output chain info
out_tine "OSCP Response"

if [[ "${OCSP_RESPONSE_CHECK_1_CODE}" == 0 ]]
then
    out_line "Check 1 : Pass" 1
else
    out_line "Check 1 : Fail" 1
    out_error "Could not verifty certificate chain."
fi

if [[ "${OCSP_RESPONSE_CHECK_2_CODE}" == 0 ]]
then
    out_line "Check 2 : Pass" 1
else
    out_line "Check 2 : Fail" 1
    out_error "Could not verifty certificate chain."
fi

if [[ "${OCSP_RESPONSE_CHECK_3_CODE}" == 0 ]]
then
    out_line "Check 3 : Pass" 1
else
    out_line "Check 3 : Fail" 1
    out_error "Could not verifty certificate chain."
fi

out_tine "Result Output"

out_line "SSL Staple File : ${SSL_CERT_DER}" 1

rm *.crt
rm *.out
