#!/bin/bash

function prompt() {
    echo -n "${1}: "
    read latest_prompt
}

prompt "Filesystem Blocksize (KiB)"
fs_blocksize=$latest_prompt

prompt "Raid VD Chunksize (KiB)"
vd_chunksize=$latest_prompt

prompt "Total number of physical disks in Raid VD"
vd_diskcount_total=$latest_prompt

prompt "VD Raid Level (ex: 0, 1, 10, 5, 6, 50, 60)"
vd_type=$latest_prompt

prompt "Fullpath to VD (ex: /dev/sda, /dev/md0, etc)"
vd_path=$latest_prompt

prompt "Provide a filesystem label for this VD"
fs_label=$latest_prompt

case "${vd_type}" in
0)
    vd_diskcount_usabe=vd_diskcount_total
    ;;
1)
    vd_diskcount_usabe=vd_diskcount_total
    ;;
10)
    vd_diskcount_usabe=`echo "${vd_diskcount_total} / 2" | bc`
    ;;
5)
    vd_diskcount_usabe=`echo "${vd_diskcount_total} - 1" | bc`
    ;;
6)
    vd_diskcount_usabe=`echo "${vd_diskcount_total} - 2" | bc`
    ;;
50)
    vd_diskcount_usabe=`echo "${vd_diskcount_total} - 2" | bc`
    ;;
60)
    vd_diskcount_usabe=`echo "${vd_diskcount_total} - 4" | bc`
    ;;
*)
    echo "Invalid VD raid type provided. Please use 0, 1, 10, 5, 6, 50, 60."
    exit
    ;;
esac

xfs_sunit=`echo "${vd_chunksize} * 1024 / 512" | bc`
xfs_swidth=`echo "${vd_diskcount_usabe} * ${xfs_sunit}" | bc`

echo -e "\nINFORMATION ON \"${vd_path}\""
echo -e "\tFilesystem blocksize (KiB) : ${fs_blocksize}"
echo -e "\tVD Chunk Size        (KiB) : ${vd_chunksize}"
echo -e "\tRaid Level of VD           : ${vd_type}"
echo -e "\tTotal Disks in VD          : ${vd_diskcount_total}"
echo -e "\tTotal Usable Disks in VD   : ${vd_diskcount_usabe}"

echo -e "\n\nXFS CALCULATIONS FOR \"${vd_path}\""
echo -e "\tStripe Value : ${xfs_sunit}"
echo -e "\tStripe Width : ${xfs_swidth}"

echo -e "\n\nXFS MKFS AND MOUNT EXAMPLES"
echo -e "\tmkfs.xfs -b size=${fs_blocksize} -d sunit=${xfs_sunit},swidth=${xfs_swidth} -L \"${fs_label}\" ${vd_path}[0-9]"
echo -e "\tmount -o remount,sunit=${xfs_sunit},swidth=${xfs_swidth}"
