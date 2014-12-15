#!/bin/bash

##
## Scribe Inc
## Backup MySQL databases and upload to Google Cloud Storage
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

SELF_SCRIPT_NAME="Google Storage - MySQL Dump/Backups"
GSUTIL_BUCKET_BASE="gs://scribe-systems-boe-mysql/"
GSUTIL_CP_OPT="-m cp -c -r "
NOW="$(date +%s)"
BASE_DIR="/mnt/storage/@tmp/gstorage-mysql-dump-and-hotbackup/"
MYSQL_DUMP_DIR_BASE="${BASE_DIR}dump/"
MYSQL_DUMP_DIR="${MYSQL_DUMP_DIR_BASE}${NOW}"
MYSQL_DUMP_CMD="${SELF_DIRPATH}/backup-databases-to-sql.bash"
MYSQL_DUMP_OPT="--be-nice"
MYSQL_DUMP_BUCKET="${GSUTIL_BUCKET_BASE}dumps/"
MYSQL_DUMP_USER="${MYSQL_CONTROL_USER}"
MYSQL_DUMP_PASS="${MYSQL_CONTROL_PASS}"
MYSQL_BACKUP_DIR_BASE="${BASE_DIR}backup/"
MYSQL_BACKUP_DIR="${MYSQL_BACKUP_DIR_BASE}${NOW}"
MYSQL_BACKUP_CMD="${SELF_DIRPATH}/backup-databases-as-hot.bash"
MYSQL_BACKUP_OPT="--be-nice"
MYSQL_BACKUP_BUCKET="${GSUTIL_BUCKET_BASE}backup/"
MYSQL_BACKUP_USER="${MYSQL_CONTROL_USER}"
MYSQL_BACKUP_PASS="${MYSQL_CONTROL_PASS}"

export BOTO_CONFIG=/opt/gsutil/.boto

##
## Function definitions
##

## Display welcome message
function out_welcome_custom
{
    out_lines \
        "${SELF_SCRIPT_NAME}" \
        "" \
        "This script handles dumping the MySQL database files and uploading them to" \
        "out Google Cloud Storage bucket."
}

## Display script usage and exit
function out_usage_custom
{
    #
    # Display script usage message
    #
    echo -en \
        "\nUsage:\n\t${SELF_FILENAME}" \
        "\n"
}

#
# check for (required) first and second parameters
#
if [[ $(echo "$@" | grep -E -e "\-?\-h(elp)?\b") ]]; then

    #
    # display usage and exit with non-zero value
    #
    out_usage

fi

##
## Require root
##
if [[ $EUID -ne 0 ]]; then
    out_empty_lines && out_error "This script must be run as root. Try sudo."
fi

## Welcome message
out_welcome

## Check for require bins
check_bins_and_setup_abs_path_vars rm gsutil

## Configuration file used
out_info \
    "Using the following configuration:" \
    "  BOTO_CONFIG         -> ${BOTO_CONFIG}" \
    "  GSUTIL_BIN          -> ${bin_gsutil}" \
    "  GSUTIL_CP_OPT       -> ${GSUTIL_CP_OPT}" \
    "  GSUTIL_BUCKET_BASE  -> ${GSUTIL_BUCKET_BASE}" \
    "  MYSQL_DUMP_DIR      -> ${MYSQL_DUMP_DIR}" \
    "  MYSQL_DUMP_CMD      -> ${MYSQL_DUMP_CMD}" \
    "  MYSQL_DUMP_USER     -> ${MYSQL_DUMP_USER}" \
    "  MYSQL_DUMP_PASS     -> ${MYSQL_DUMP_PASS}" \
    "  MYSQL_DUMP_BUCKET   -> ${MYSQL_DUMP_BUCKET}" \
    "  MYSQL_BACKUP_DIR    -> ${MYSQL_BACKUP_DIR}" \
    "  MYSQL_BACKUP_CMD    -> ${bin_innobackupex}" \
    "  MYSQL_BACKUP_OPT    -> ${MYSQL_BACKUP_OPT}" \
    "  MYSQL_BACKUP_USER   -> ${MYSQL_BACKUP_USER}" \
    "  MYSQL_BACKUP_PASS   -> ${MYSQL_BACKUP_PASS}" \
    "  MYSQL_BACKUP_BUCKET -> ${MYSQL_BACKUP_BUCKET}" \

out_stage \
    "1" \
    "4" \
    "MySQL Dumps"

out_commands \
    "Executing MySQL Dumps" \
    "mkdir -p "${MYSQL_DUMP_DIR}"" \
    "cd "${MYSQL_DUMP_DIR}"" \
    "${MYSQL_DUMP_CMD} ${MYSQL_DUMP_OPT}"

mkdir -p "${MYSQL_DUMP_DIR}" && cd "${MYSQL_DUMP_DIR}"
${MYSQL_DUMP_CMD} ${MYSQL_DUMP_OPT}

out_empty_lines && out_success "MySQL Dump: Complete"

out_stage \
    "2" \
    "4" \
    "Upload MySQL Dumps"

out_commands \
    "Uploading MySQL Dumps" \
    "cd \"${MYSQL_DUMP_DIR}\"" \
    "${bin_gsutil} ${GSUTIL_CP_OPT} \"./\" \"${MYSQL_DUMP_BUCKET}\"" \
    "${bin_rm} -fr ${MYSQL_DUMP_DIR}"

cd "${MYSQL_DUMP_DIR}"
${bin_gsutil} ${GSUTIL_CP_OPT} "./" "${MYSQL_DUMP_BUCKET}"
${bin_rm} -fr ${MYSQL_DUMP_DIR}

out_empty_lines && out_success "Upload MySQL Dump: Complete"

out_stage \
    "3" \
    "4" \
    "MySQL InnoDB Hot-Backup"

out_commands \
    "Executing MySQL InnoDB Hot-Backup" \
    "mkdir -p \"${MYSQL_BACKUP_DIR_BASE}\" && cd \"${MYSQL_BACKUP_DIR_BASE}\"" \
    "${MYSQL_BACKUP_CMD} ${MYSQL_BACKUP_OPT}"

mkdir -p "${MYSQL_BACKUP_DIR_BASE}" && cd "${MYSQL_BACKUP_DIR_BASE}"
${MYSQL_BACKUP_CMD} ${MYSQL_BACKUP_OPT}

out_empty_lines && out_success "MySQL InnoDB Hot-Backup: Complete"

out_stage \
    "4" \
    "4" \
    "Upload MySQL InnoDB Hot-Backup"

out_commands \
    "Uploading MySQL InnoDB Hot-Backup" \
    "mkdir -p cd \"${MYSQL_BACKUP_DIR}\"" \
    "${bin_gsutil} ${GSUTIL_CP_OPT} \"./\" \"${MYSQL_BACKUP_BUCKET}\"" \
    "${bin_rm} -fr ${MYSQL_BACKUP_DIR}"

cd "${MYSQL_BACKUP_DIR}"
${bin_gsutil} ${GSUTIL_CP_OPT} "./" "${MYSQL_BACKUP_BUCKET}"
${bin_rm} -fr ${MYSQL_BACKUP_DIR}

out_empty_lines && out_success "Upload MySQL InnoDB Hot-Backup: Complete"

out_done "All operations completed."

## Exit
exit 0

## EOF
