#!/bin/bash
###
# ABOUT  : collectd monitoring script for smartmontools (using smartctl)
# AUTHOR : Samuel B. <samuel_._behan_(at)_dob_._sk> (c) 2012
# LICENSE: GNU GPL v3
#
# This script monitors SMART pre-fail attributes of disk drives using smartmon tools.
# Generates output suitable for Exec plugin of collectd.
# 
# Requirements:
#   smartmontools installed (and smartctl binary)
#   sudo entry for binary (ie. for sys account):
#       sys   ALL = (root) NOPASSWD: /usr/sbin/smartctl
#
# Parameters:
#   <disk>[:<driver>,<id> ] ...
#
# Typical usage:
#   /etc/collect/smartmon.sh "sda:megaraid,4" "sdb"
#
#   Will monitor disk 4, of megaraid adapter mapped as /dev/sda and additionaly
#   normal disk /dev/sdb. See smartctl manual for more info about adapter driver names.
#
# Typical output:
#   PUTVAL <host>/smartmon-sda4/gauge-raw_read_error_rate interval=300 N:30320489
#   PUTVAL <host>/smartmon-sda4/gauge-spin_up_time interval=300 N:0
#   PUTVAL <host>/smartmon-sda4/gauge-reallocated_sector_count interval=300 N:472
#   PUTVAL <host>/smartmon-sda4/gauge-end_to_end_error interval=300 N:0
#   PUTVAL <host>/smartmon-sda4/gauge-reported_uncorrect interval=300 N:1140
#   PUTVAL <host>/smartmon-sda4/gauge-command_timeout interval=300 N:85900918876
#   PUTVAL <host>/smartmon-sda4/temperature-airflow interval=300 N:31
#   PUTVAL <host>/smartmon-sda4/temperature-temperature interval=300 N:31
#   PUTVAL <host>/smartmon-sda4/gauge-offline_uncorrectable interval=300 N:5
#   PUTVAL <host>/smartmon-sdb/gauge-raw_read_error_rate interval=300 N:0
#   PUTVAL <host>/smartmon-sdb/gauge-spin_up_time interval=300 N:4352
#   ...
#
# Monitoring additional attributes:
#   If it is needed to monitor additional SMART attributes provided by smartctl, you
#   can do it simply by echoing SMART_<Attribute-Name> environment variable as its output
#   by smartctl -A. It's nothing complicated ;)
#
# History:
#   2012-04-17 v0.1.0  - public release
#   2012-09-03 v0.1.1  - fixed dash replacemenet (thx to R.Buehl)
###

if [ -z "$*" ];
then	echo "usage: $0 <disk> <disk>..." >&2;
	exit 1;
fi;

for disk in "$@";
do	disk=${disk%:*};
	if ! [ -e "/dev/$disk" ];
	then	echo "$0: disk /dev/$disk not found !" >&2;
		exit 1;
	fi;
done;

HOST="${COLLECTD_HOSTNAME:-$(hostname -f)}"
INTERVAL="${COLLECTD_INTERVAL:-60}"

while sleep "$INTERVAL"
do
	for disk in "$@";
	do  dsk=${disk%:*};
	    drv=${disk#*:};
	    id=;

	    if [ "$disk" != "$drv" ];
	    then	drv="-d $drv";
			id=${drv#*,};
	    else	drv=;
	    fi;

	    eval `smartctl $drv -A "/dev/$dsk" | awk '$3 ~ /^0x/ && $2 ~ /^[[:alnum:]_-]+$/ { gsub(/-/, "_"); print "SMART_" $2 "=" $10 }' 2>/dev/null`;

	    echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-raw_read_error_rate interval=$INTERVAL N:${SMART_Raw_Read_Error_Rate:-U}";
	    echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-spin_up_time interval=$INTERVAL N:${SMART_Spin_Up_Time:-U}";
	    echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-reallocated_sector_count interval=$INTERVAL N:${SMART_Reallocated_Sector_Ct:-U}";
	    [ -n "$SMART_End_to_End_Error" ] && echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-end_to_end_error interval=$INTERVAL N:${SMART_End_to_End_Error:-U}";
	    [ -n "$SMART_Reported_Uncorrect" ] && echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-reported_uncorrect interval=$INTERVAL N:${SMART_Reported_Uncorrect:-U}";
	    [ -n "$SMART_Command_Timeout" ] && echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-command_timeout interval=$INTERVAL N:${SMART_Command_Timeout:-U}";
            [ -n "$SMART_Airflow_Temperature_Cel" ] && echo "PUTVAL $HOST/smartmon-$dsk$id/temperature-airflow interval=$INTERVAL N:${SMART_Airflow_Temperature_Cel:-U}";
	    echo "PUTVAL $HOST/smartmon-$dsk$id/temperature-temperature interval=$INTERVAL N:${SMART_Temperature_Celsius:-U}";
	    echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-offline_uncorrectable interval=$INTERVAL N:${SMART_Offline_Uncorrectable:-U}";
	done;
done
