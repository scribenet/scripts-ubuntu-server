#!/bin/bash

egrep -v '^#' /etc/fstab | while read dev dir type opts dump pass ; do
    echo "mount -o remount,${opts} ${dir}";
done
