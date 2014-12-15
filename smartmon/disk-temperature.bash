#!/bin/sh

PATH=/root/bin:/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

HDDS=`sysctl -n kern.disks | sed 's/cd0//'`
HOSTNAME="${COLLECTD_HOSTNAME:-`hostname -f`}"
INTERVAL="${COLLECTD_INTERVAL:-60}"

INTERVAL=`echo $INTERVAL | sed 's/^\(.*\)\..*$/\1/'`

while true; do
        CYCLE_START=`date +%s`

        for HDD in $HDDS; do
                TEMP=`(sudo smartctl -A $HDD | grep Temperature_Celsius | awk '{ print $10; }') 2>/dev/null`
                if [ $? -ne 0 -o -z "$TEMP" ]; then
                        TEMP="U"
                fi

                echo "PUTVAL $HOSTNAME/exec/temperature-$HDD interval=$INTERVAL N:$TEMP"
        done

        CYCLE_END=`date +%s`
        DIFF=`expr $CYCLE_END - $CYCLE_START`
        if [ $DIFF -lt $INTERVAL ]; then
                sleep `expr $INTERVAL - $DIFF`
        fi
done
