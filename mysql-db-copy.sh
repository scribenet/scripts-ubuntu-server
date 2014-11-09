#!/bin/bash

##
## Scribe Inc
## Copy a specific database
##

#
# check for (required) parameter
#
if [[ -z "${1}" ]] || [[ -z "${2}" ]]; then

  #
  # display usage and exit with non-zero value
  #
  echo -e "Usage:\n\t${0} db_name root_password"
  exit 1

else

  #
  # define db user and password
  #
  db_name="${1}"
  db_pass="${2}"
  db_user="root"

fi

#
# database host
#
db_host="localhost"

#
# backup name 
#
backup_db_name="${db_name}-bk-$(date +%y%m%d%H%M%S)"

#
# find executable absolute locations
#
mysql="$(which mysql)"
mysqldump="$(which mysqldump)"

#
# user output
#
echo "Creating backup db: ${backup_db_name}"

#
# create the new db
#
echo "CREATE DATABASE \`${backup_db_name}\`" | $mysql -u"${db_user}" -p"${db_pass}"

#
# user output
#
echo "Copying ${db_name} to ${backup_db_name}... This could take some time."

#
# copy db
#
$mysqldump -u"${db_user}" -p"${db_pass}" "${db_name}" | mysql -u"${db_user}" -p"${db_pass}" "${backup_db_name}"; 

#
# exit cleanly
#
exit 0

#
# EOF
#
