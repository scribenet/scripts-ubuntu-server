#!/bin/bash

##
## Scribe Inc
## Dump MySQL Database's to SQL
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
db_user="${MYSQL_CONTROL_USER}"
db_pass="${MYSQL_CONTROL_PASS}"
db_host="localhost"
db_exclude="information_schema"
out_dir="$(pwd)"
bin_compress="pigz"
enable_compression=1
enable_ionice=0
enable_nice=0
opt_compress="-8 --blocksize 32 --processes 40"
opt_mysql="--single-transaction --quick --lock-tables=false --tz-utc"
opt_ionice="-c2 -n7"
opt_nice="-n20"

##
## Internal Configuration
##
SELF_SCRIPT_NAME="MySQL Backup (Dump)"
OUT_PROMPT_DEFAULT="y"

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
        "This script quieries the MySQL database and creates individual SQL dumps for each, with" \
        "support for compressing the database dumps using the multi-threaded gz compression "\
        "utility Pigz. If you prefer an alternate compression format, command, or would like to"\
        "avoid compression alltogether, this can be configured as well."
}

## Display script usage and exit
function out_usage_custom
{
    #
    # Display usage message test
    #
    out_usage_optls "[-u | --mysql-user]" "[-p | --mysql-pass]" "[-n | --no-compress]" "[-e | --exclude-dbs]" "[-o | --out-dir]" "[--ionice]" "[--nice]" "[-h | --help]"

    out_usage_optdt 0 "-u user" "--mysql-user user"
    out_usage_optdd \
        "A MySQL user to use. The configured control dbuser will be used by default."
    out_usage_optdt 0 "-p pass" "--mysql-pass pass"
    out_usage_optdd \
        "A MySQL password to use. The configured control dbpass will be used by default."
    out_usage_optdt 0 "-n" "--no-compress"
    out_usage_optdd \
        "Disable compression of the output files. Compession requires ${bin_compress} by default."
    out_usage_optdt 0 "-e \"db1 db2 db3\"" "--exclude-dbs \"db1 db2 db3\""
    out_usage_optdd \
        "Exclude a set of databases. The following are excluded by default: ${db_exclude}."
    out_usage_optdt 0 "-o \"/backup/path\"" "--out-dir \"/backup/path\""
    out_usage_optdd \
        "An output directory for the backup. The current directory is used by default."
    out_usage_optdt 0 "--use-nice"
    out_usage_optdd \
        "Enable nice. Uses the parameters ${opt_nice}."
    out_usage_optdt 0 "--use-ionice"
    out_usage_optdd \
        "Enable ionice. Uses the parameters ${opt_ionice}."
    out_usage_optdt 0 "--be-nice"
    out_usage_optdd \
        "Enable both nice and ionice."
    out_usage_optdt 0 "-h" "--help"
    out_usage_optdd \
        "Display this help dialoge."

}

#
# Check for (required) first and second parameters
#
if [[ $(echo "$@" | grep -E -p "\-?\-h(elp)?\b") ]]; then

    #
    # Display usage and exit with non-zero value
    #
    out_usage

else

    #
    # setup triggers for options
    #
    last_option=""

    #
    # Loop through any remaining options and apply them
    #
    for opt in "${@}"; do

        if [[ "${last_option}" == "mysql-user" ]]; then

            db_user="${opt}"
            last_option=""
            continue

        elif [[ "${last_option}" == "mysql-pass" ]]; then

            db_pass="${opt}"
            last_option=""
            continue

        elif [[ "${last_option}" == "exclude-dbs" ]]; then

            db_exclude="${opt}"
            last_option=""
            continue

        elif [[ "${last_option}" == "out-dir" ]]; then

            out_dir="${opt}"
            last_option=""
            continue

        elif [[ "${opt}" == "-u" ]] || [[ "${opt}" == "--mysql-user" ]]; then

            last_option="mysql-user"
            continue

        elif [[ "${opt}" == "-p" ]] || [[ "${opt}" == "--mysql-pass" ]]; then

            last_option="mysql-pass"
            continue

        elif [[ "${opt}" == "-n" ]] || [[ "${opt}" == "--no-compress" ]]; then

            enable_compression=0
            continue

        elif [[ "${opt}" == "-e" ]] || [[ "${opt}" == "--exclude-dbs" ]]; then

            last_option="exclude-dbs"
            continue

        elif [[ "${opt}" == "-o" ]] || [[ "${opt}" == "--out-dir" ]]; then

            last_option="out-dir"
            continue

        elif [[ "${opt}" == "--use-nice" ]]; then

            enable_nice=1
            continue

        elif [[ "${opt}" == "--use-ionice" ]]; then

            enable_ionice=1
            continue

        elif [[ "${opt}" == "--be-nice" ]]; then

            enable_nice=1
            enable_ionice=1
            continue

        fi

    done

fi

## Welcome message
out_welcome

## Check for require bins
required_bins="mysql mysqldump date hostname date wc sed uname"
if [[ ${enable_compression} == 1 ]]; then required_bins="${bin_compress} ${required_bins}"; fi
if [[ ${enable_nice} == 1 ]]; then required_bins="nice ${required_bins}"; fi
if [[ ${enable_ionice} == 1 ]]; then required_bins="ionice ${required_bins}"; fi
check_bins_and_setup_abs_path_vars $required_bins
if [[ ${enable_compression} == 0 ]]; then bin_compress="which ${bin_compress}"; fi

## Edge case for Darwin
if [[ "$(${bin_uname} -s)" == "Darwin" ]]; then opt_ionice=""; fi

## Get hostname
hostname="$(${bin_hostname})"

#
# current date
#
now="$(${bin_date} +"%Y%m%d-%H%M")"

#
# directory path for backups
#
mbd="${out_dir}/"

#
# get list of all databases from mysql server
#
dbs="$(${bin_mysql} -u ${db_user} -h ${db_host} -p${db_pass} -Bse 'show databases' 2> /dev/null)"
db_count="$(echo ${dbs} | ${bin_wc} -w | tr -d ' ')"

## Show runtime configuration setup
out_info_config \
    "Runtime Configuration:" \
    "" \
    "  DB Username -> ${db_user}" \
    "  DB Password -> $(echo ${db_pass} | sed -r 's/(.{5}).*/\1*****/g')" \
    "  DB Hostname -> ${db_host}" \
    "" \
    "  DB Count    -> ${db_count}" \
    "  DB List     -> $(echo ${dbs} | ${bin_sed} 's/\n$/ /')" \
    "  Exclude DBs -> ${db_exclude}" \
    "" \
    "  Output Dir  -> ${mbd}" \
    "" \
    "  Compression -> $(if [[ ${enable_compression} -eq 0 ]]; then echo "Disabled"; else echo "Enabled [${bin_compress} ${opt_compress}]"; fi)" \
    "  Nice        -> $(if [[ ${enable_nice} -eq 0 ]]; then echo "Disabled"; else echo "Enabled [${bin_nice} ${opt_nice}]"; fi)" \
    "  IoNice      -> $(if [[ ${enable_ionice} -eq 0 ]]; then echo "Disabled"; else echo "Enabled [${bin_ionice} ${opt_ionice}]"; fi)"

## Allow the user to bail
out_prompt_boolean "0" "Would you like to continue?" "Confirm Config" "y"

## Setup iterator
j=1
total=$(( ${db_count} - $(echo ${db_exclude} | ${bin_wc} -w) ))

## Setup pre-command
pre_command=""
if [[ ${enable_nice} -eq 1 ]]; then pre_command="${bin_nice} ${opt_nice} "; fi
if [[ ${enable_ionice} -eq 1 ]]; then pre_command="${pre_command}${bin_ionice} ${opt_ionice} "; fi

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
    if [ "${db_exclude}" != "" ]; then

        #
        # for each db to ignore...do
        #
        for i in $db_exclude; do

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

        out_stage \
            "${j}" \
            "${total}" \
            "Exporting: ${db}"

        #
        # set the backup filepath
        #
        filepath="${mbd}/${db}.${hostname}.${now}.sql"

        #
        # perform the backup for this database, if compression is enabled, handle
        # gzip operation using the pipe so it occurs in-memory before dumping the
        # result to a file (much faster)
        #
        if [[ "${enable_compression}" == "0" ]]; then

            ${pre_command}${bin_mysqldump} ${opt_mysql} -u"${db_user}" -h"${db_host}" -p"${db_pass}" "${db}" > $filepath 2> /dev/null

        else

            filepath="${filepath}.gz"
            ${pre_command}${bin_mysqldump} ${opt_mysql} -u"${db_user}" -h"${db_host}" -p"${db_pass}" "${db}" 2> /dev/null | ${pre_command}${bin_compress} ${opt_compress} > $filepath

        fi

        out_success \
            "Step ${i}: Complete" \
            "  Output File -> $filepath"

        j=$(( j + 1 ))

    fi

done

out_done "Completed all operations!"

#
# exit cleanly
#
exit 0

#
# EOF
#
