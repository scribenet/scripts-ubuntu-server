#!/bin/bash

##
## Scribe Inc
## Dump MySQL Database's to SQL
##

## Where are we?
SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

##
## Include common functions
##
source ${SELF_DIR}/../common/common.bash

##
## User Configuration
##
opt_compress="-8 --blocksize 32 --processes 40"
use_compress="pigz"
enable_compression=1
opt_mysql="--single-transaction --quick --lock-tables=false --tz-utc"
db_host="localhost"
use_mysql="mysql"
explude_dbs="information_schema"
out_dir="$(pwd)"
opt_ionice="-c2 -n7"
opt_nice="-n20"

##
## Internal Configuration
##
SELF_SCRIPT_NAME="MySQL Dump to SQL"
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
    out_usage_optls "<db_user>" "<db_pass>" "[-h | --help]" "[-n | --no-compress]" "[-e | --exclude-dbs]" "[-o | --out-dir]"

    out_usage_optdt 1 "<db_user>"
    out_usage_optdd \
        "The first two arguments MUST be the username and password to connect to the MySQL server, the
        first argument being the username. Be sure the user has the required permissions to
        perform this task."
    out_usage_optdt 1 "<db_pass>"
    out_usage_optdd \
        "The second argument MUST be the MySQL password used to connect to the database."
    out_usage_optdt 0 "-h" "--help"
    out_usage_optdd \
        "Display this help dialoge."
    out_usage_optdt 0 "-n" "--no-compress"
    out_usage_optdd \
        "Compression of the dumped SQL exports is enabled by default. To disable this features, you
        may pass this argument. Alternativly, if you would like to change the program arguments, or
        implementation all-together, you may do so by editing the configuration at the top of this
        script."
    out_usage_optdt 0 "-e 'one two three'" "--exclude-dbs 'one two three'"
    out_usage_optdd \
        "By default, the following databases are expluded from backup: ${db_ignore}. You may either
        pass this as an empty paramiter to clear the default excluded databases, or pass a complete
        new list of databases to exclude."
    out_usage_optdt 0 "-o '/some/path'" "--out-dir '/some/path'"
    out_usage_optdd \
        "If left unconfigured, the MySQL dumps are exported to the current working directory. If you
        would like to customize this behaviour, pass this option."

}

#
# Check for (required) first and second parameters
#
if [[ $# -lt 2 ]] || [[ "${1}" == "-h" ]] || [[ "${1}" == "--help" ]]; then

    #
    # Display usage and exit with non-zero value
    #
    out_usage

else

    #
    # Set the username and password
    #
    db_user="${1}"
    db_pass="${2}"

    #
    # setup triggers for options
    #
    last_option=""

    #
    # Loop through any remaining options and apply them
    #
    for opt in "${@:3}"; do

        echo "${opt}"

        if [[ "${last_option}" == "exclude-dbs" ]]; then

            explude_dbs="${opt}"
            last_option=""
            continue

        elif [[ "${last_option}" == "out-dir" ]]; then

            out_dir="${opt}"
            last_option=""
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

        fi

    done

fi

## Welcome message
out_welcome

## Check for require bins
check_bins_and_setup_abs_path_vars "${use_compress}" "${use_mysql}" mysqldump ionice nice date hostname date wc sed

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
db_count="$(echo ${dbs} | ${bin_wc} -w)"

## Show runtime configuration setup
out_info_config \
    "Runtime Configuration:" \
    "" \
    "  DB Username -> ${db_user}" \
    "  DB Password -> ${db_pass}" \
    "  DB Hostname -> ${db_host}" \
    "" \
    "  DB Count    -> ${db_count}" \
    "  DB List     -> $(echo ${dbs} | ${bin_sed} 's/\n$/ /')" \
    "  Exclude DBs -> ${explude_dbs}" \
    "" \
    "  Output Dir  -> ${mbd}" \
    "  Compression -> $(if [[ ${enable_compression} -eq 0 ]]; then echo "Disabled"; else echo "Enabled"; fi)"

## Allow the user to bail
out_prompt_boolean "0" "Would you like to continue?" "Confirm Config" "y"

## Setup iterator
j=1
total=$(( ${db_count} - $(echo ${explude_dbs} | ${bin_wc} -w) ))

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
    if [ "${explude_dbs}" != "" ]; then

        #
        # for each db to ignore...do
        #
        for i in $explude_dbs; do

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
        # perform the backup for this database, handle gzip operation using the pipe
        # so it occurs in-memory before dumping the result to a file
        #
        if [[ "${enable_compression}" == "0" ]]; then

            ${bin_mysqldump} ${opt_mysql} -u"${db_user}" -h"${db_host}" -p"${db_pass}" "${db}" > $filepath 2> /dev/null

        else

            filepath="${filepath}.gz"
            ${bin_mysqldump} ${opt_mysql} -u"${db_user}" -h"${db_host}" -p"${db_pass}" "${db}" 2> /dev/null | ${bin_pigz} ${opt_compress} > $filepath

        fi

        out_success \
            "Step ${i}: Complete" \
            "  Output File -> $filepath"

        j=$(( j + 1 ))

    fi

done

out_success "Completed all operations!"

#
# exit cleanly
#
exit 0

#
# EOF
#
