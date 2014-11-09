#!/bin/sh

# Arg 1: -rf
# Arg 2: /testbtrfs/backups/hourly.4/

# echo 1: $1  2: $@

# Try to delete the given path with btrfs subvolume delete first
# if this fails fall back to normal rm
if [  "$1" = "-rf"  -a  "$3" = ""  ]; then
        # "trying to delete with btrfs"
        btrfs subvolume delete $2
        error=$?
        if [ $error -eq 13 ]; then
                # EC 13 => The directory specified is no subvolume
                rm $@
        elif [ $error -ne 0 ]; then
                echo Error while deleting with btrfs $?
        fi
else
        rm $@
fi
