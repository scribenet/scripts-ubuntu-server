#!/bin/bash

##
## Scribe Inc
## Perform a hot-backup of ${bin_mysql} data
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

## Display welcome message
function out_welcome_custom
{
    #
    # Display welcome message text
    #
    out_lines \
        "${SELF_SCRIPT_NAME}" \
        "" \
        "This script handles optimizing (defragmenting) all mysql tables for a given host."
}

#
# Check for (required) first and second parameters
#
if [[ $(echo "$@" | grep -E -e "\-?\-h(elp)?\b") ]]; then

    #
    # Display usage and exit with non-zero value
    #
    out_usage

fi

## Welcome message
out_welcome

## Check for require bins
check_bins_and_setup_abs_path_vars mysql grep mysql_config_editor

${bin_mysql_config_editor} set --skip-warn --login-path=local --host=localhost --user=${db_user} --password=${db_pass}

${bin_mysql} --login-path=local -NBe "SHOW DATABASES;" | ${bin_grep} -v 'lost+found' | while read database ; do
${bin_mysql} --login-path=local -NBe "SHOW TABLE STATUS;" $database | while read name engine version rowformat rows avgrowlength datalength maxdatalength indexlength datafree autoincrement createtime updatetime checktime collation checksum createoptions comment ; do
        if [ "$datafree" != "NULL" ] && [ "$datafree" -gt 0 ] ; then
            fragmentation=$(($datafree * 100 / $datalength))
            echo " - $database.$name is $fragmentation% fragmented."
            echo "   |- Size      : $(( $datalength / 1024 / 1024 )) MB"
            echo -n "   |- Action    : "
            if [ "$database.$name" == "world-dev.ProjectFileContent" ] ; then
                echo "Skipping per explicit request."
            else
                echo "Performing optomization routing."
                echo "   |- Command   : ${bin_mysql} --login-path=local -NBe \"OPTIMIZE TABLE '$name';\" \"$database\""
                echo -n "   |- Optimizing:"
                ${bin_mysql} --login-path=local -NBe "OPTIMIZE TABLE $name;" "$database" > /dev/null
                if [ "$?" -eq 0 ]; then
                    echo "Complete!"
                else
                    echo "FAILURE!"
                    sleep 20
                fi
            fi
            echo ""
        fi
    done
done

out_done "Completed!"

## EOF