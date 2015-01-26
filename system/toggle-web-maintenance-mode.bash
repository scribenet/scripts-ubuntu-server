#!/bin/bash

##
## Maintenance Mode Toggle
##
## This script toggles the Nginx enabled site configuration between normal mode and
## maintenance mode. In the latter mode, all requests direct to a static page informing
## the user that our web services are currently unavailable.
##

set -e

##
## Configuration
##

## Directory paths for Nginx config per mode
NGINX_SITES_DISABLED_DIR="/etc/nginx/sites-enabled"
NGINX_SITES_DISABLED_DIR_OFFLINE="/etc/nginx/.sites-enabled"
NGINX_SITES_ENABLED_DIR="/etc/nginx/sites-enabled"
NGINX_SITES_ENABLED_DIR_OFFLINE="/etc/nginx/.sites-offline"

## Mode values accepted as script arguments
MODE_OFF="off"
MODE_ON="on"

## Path to datetime text file for when maintenance mode is enabled
TEXT_STATUS_FILEPATH="/www/_internal-share/offline/text-back-online.txt"

##
## Function definitions
##

## Display script usage and exit
function out_usage
{
  echo -en \
    "\nUsage:\n\t${0} ${MODE_OFF}|${MODE_ON} [expected-resolution-time]\n" \
    "\n\t${MODE_OFF}|${MODE_ON}" \
    "\n\t\tYou must supply either '${MODE_OFF}' or '${MODE_ON}' for the first parameter." \
    "\n\t\tSetting maintenance mode to '${MODE_ON}' results in all web-requests redirecting" \
    "\n\t\tto the scheduled maintenance page. The mode option '${MODE_OFF}' re-enables" \
    "\n\t\tnormal site operations." \
    "\n\n\texpected-resolution-time" \
    "\n\t\tIf this optional parameter is provided, an expected resolution date and" \
    "\n\t\ttime will be provided to the user on the maintenance page, otherwise the" \
    "\n\t\tthe page will say 'shortly'." \
    "\n\t\t  The provided string must be an ISO-compliant date format that moment.js" \
    "\n\t\tcan parse. An example is 2014/11/09 18:00 -0500. For additional supported" \
    "\n\t\tformatts see http://momentjs.com/docs/#/parsing/string/.\n\n"
  exit 1
}

## Output passed arguments as lines
function out_lines
{
  for line in "${@}"
  do
    echo -en "# ${line}\n"
  done
}

## Display welcome message
function out_welcome
{
  tput setaf 7
  echo -en "\n##\n#\n"
  out_lines \
    "Maintenance Mode Toggle" \
    "" \
    "This script toggles the Nginx enabled site configuration between normal mode and" \
    "maintenance mode. In the latter mode, all requests direct to a static page informing" \
    "the user that our web services are currently unavailable." \
    "" \
    "Author    : Rob Frawley 2nd <rfrawley@scribenet.com>" \
    "Copyright : 2014 Scribe Inc." \
    "License   : MIT License (2-clause)"
  echo -en "#\n##\n\n"
  tput sgr0
}

## Display error message and exit
function out_error
{
  tput bold
  tput setaf 1
  echo -en "#\n# ERROR\n#\n"
  out_lines "${@}"
  echo -en "#\n\n"
  tput sgr0
  exit 2
}

## Display notice/warning message
function out_notice
{
  tput bold
  tput setaf 3
  out_lines "${@}"
  echo -en "\n"
  tput sgr0
}

## Display info messages
function out_info
{
  tput bold
  tput setaf 6
  out_lines "${@}"
  echo -en "\n"
  tput sgr0
}

##
## Check for (required) first parameter
##
if [[ -z "${1}" ]]; then

  out_usage

else

  ## Only accept configured enabled/disabled strings
  if [[ "${1}" != "${MODE_OFF}" && "${1}" != "${MODE_ON}" ]]; then

    out_usage

  else

    MODE="${1}"

  fi

fi

## Output welcome message
out_welcome

##
## This script can only be run by root
##
if [[ $EUID -ne 0 ]]; then

   out_error "This script must be run as root. Try sudo."
   exit 1

fi

##
## Cannot disable if already disabled or enable if already enabled
##
if [[ $MODE == $MODE_OFF && -d ${NGINX_SITES_ENABLED_DIR_OFFLINE} ]]; then

  out_error "Maintenance mode is already off."

elif [[ $MODE == $MODE_ON && -d ${NGINX_SITES_DISABLED_DIR_OFFLINE} ]]; then

  out_error "Maintenance mode is already on."

fi

##
## Let the user know what mode we are switching to
##
out_info "Handling request:" \
  "  Mode -> ${MODE}"

##
## Reset text status file
##
set +e
rm ${TEXT_STATUS_FILEPATH}
set -e
touch ${TEXT_STATUS_FILEPATH}

##
## Move sites-enabled directory per requested mode
##
if [[ $MODE == $MODE_ON ]]; then

  ## Move nginx directories such that offline is only enabled site
  mv ${NGINX_SITES_DISABLED_DIR} ${NGINX_SITES_DISABLED_DIR_OFFLINE}
  mv ${NGINX_SITES_ENABLED_DIR_OFFLINE} ${NGINX_SITES_ENABLED_DIR}

  ## Check for passed second parameter (string containing expected restoration time)
  if [[ -n "${2}" ]]; then

    out_info "Setting expected resolution:" \
      "  Datetime -> ${2}"
    echo "${2}" > ${TEXT_STATUS_FILEPATH}

  else

    out_notice "While not required, it is recommended to pass a resolution time as the second argument."

  fi

else

  ## Move nginx directories such that regular site config is restored
  mv ${NGINX_SITES_ENABLED_DIR} ${NGINX_SITES_ENABLED_DIR_OFFLINE}
  mv ${NGINX_SITES_DISABLED_DIR_OFFLINE} ${NGINX_SITES_DISABLED_DIR}

fi

##
## Restart nginx
##
out_info "Applying new configuration to Nginx:" \
  "  Action -> Reloading"
service nginx reload > /dev/null

out_info "Done."

##
## Exit cleanly
##
exit 0

## EOF
