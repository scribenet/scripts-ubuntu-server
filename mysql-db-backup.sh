#!/bin/bash

##
## Scribe Inc
## Pull all mysql databases for backup (rsnapshot) consumption
##

#
# configurable options
#
opt_ionice="-c2 -n7"
opt_nice="-n20"
opt_compress="-8 --blocksize 32 --processes 20"
opt_mysql="--single-transaction --quick --lock-tables=false"

#
# find executable absolute locations
#
bin_mysql="$(which mysql)"
bin_mysqldump="$(which mysqldump)"
bin_chown="$(which chown)"
bin_chmod="$(which chmod)"
bin_compress="$(which pigz)"
bin_ionice="$(which ionice)"
bin_nice="$(which nice)"
bin_date="$(which date)"
bin_hostname="$(which hostname)"

#
# check for (required) first and second parameters
#
if [[ -z "${1}" ]] || [[ -z "${2}" ]]; then

  #
  # display usage and exit with non-zero value
  #
  echo -e "Usage:\n\t${0} db_user db_pass [--no-compression]"
  exit 1

else

  #
  # define db user and password
  #
  db_user="${1}"
  db_pass="${2}"

fi

if [[ "${3}" == "--no-compression" ]]; then

  echo "Disabling compression of output files."
  ENABLE_COMPRESS=0

else

  echo "Enabling compression of output files using ${bin_compress}."
  ENABLE_COMPRESS=1

fi

#
# database host
#
db_host="localhost"

#
# backup directory
#
backup_dir="$PWD"

#
# find executable absolute locations
#
bin_mysql="$(which mysql)"
bin_mysqldump="$(which mysqldump)"
bin_chown="$(which chown)"
bin_chmod="$(which chmod)"
bin_compress="$(which pigz)"
bin_ionice="$(which ionice)"
bin_nice="$(which nice)"
bin_date="$(which date)"
bin_hostname="$(which hostname)"

#
# get system hostname
#
hostname="$(hostname)"

#
# current date
#
now="$(date +"%Y%d%m-%H%M")"

#
# directory path for backups
#
mbd="${backup_dir}/"

#
# list of databases to ignore
#
db_ignore="information_schema phpmyadmin test"

#
# if the backup directory doesn't exist, create it
#
[ ! -d "$mbd" ] && mkdir -p "$mbd" || :

# Only root can access it!
#$CHOWN 0.0 -R $DEST
#$CHMOD 0600 $DEST

#
# get list of all databases from mysql server
#
dbs="$(${mysql} -u ${db_user} -h ${db_host} -p${db_pass} -Bse 'show databases' 2> /dev/null)"

#
# for each db entry found...do
#
for db in $dbs; do

  #
  # "should this database be skipped?" flag
  #
  skipdb=-1

  #
  # if the db ignore list isn't empty...
  #
  if [ "${db_ignore}" != "" ]; then

    #
    # for each db to ignore...do
    #
    for i in $db_ignore; do

      #
      # if this db should be skipped, set the skipdb flag
      #
      [ "$db" == "$i" ] && skipdb=1 || :

    done

  fi

  #
  # if no skip flag is set, we're good to go
  #
  if [ "$skipdb" == "-1" ]; then

    #
    # set the backup filepath
    #
    filepath="${mbd}/${db}.${hostname}.${now}.sql"

    #
    # Output db
    #
    echo -en "Exporting ${db}..."

    #
    # perform the backup for this database, handle gzip operation using the pipe
    # so it occurs in-memory before dumping the result to a file
    #
    if [[ "${ENABLE_PIGS}" == "0" ]]; then

      $mysqldump --single-transaction --tz-utc -u"${db_user}" -h"${db_host}" -p"${db_pass}" "${db}" > $filepath 2> /dev/null

    else

      filepath="${filepath}.gz"
      $mysqldump --single-transaction --tz-utc -u"${db_user}" -h"${db_host}" -p"${db_pass}" "${db}" 2> /dev/null | $gzip $gzipopts > $filepath

    fi

    echo "saved to $(basename ${filepath})"

  fi

done

#
# exit cleanly
#
exit 0

#
# EOF
#
