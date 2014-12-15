#!/bin/bash

##
## Scribe Inc
## Monitor both Adaptec and Intel raid
##

if [[ ${EUID} -ne 0 ]]; then

  #
  # let user know this needs to be run as root
  #
  echo "Please re-run this command as root and try again..."
  exit 1

fi

echo -en "\n$(date)\n"

#
# inform user what we are about to output
#
echo ""
echo "   +-------------------------------------------------------------+   "
echo "   | MDADM BENCHMARK                                             |   "
echo "   | (boot,system,www drive, raid 1,1,0, using hdparm)           |   "
echo "   +-------------------------------------------------------------+   "

#
# benchmark system disk
#
hdparm -tT /dev/md0
hdparm -tT /dev/md1
hdparm -tT /dev/md2

#
# inform user what we are about to output
#
echo ""
echo "   +-------------------------------------------------------------+   "
echo "   | SAMSUNG DISK HEALTH                                         |   "
echo "   | (/dev/sda,/dev/sdb, using smartctl)                         |   "
echo "   +-------------------------------------------------------------+   "
echo ""

#
# do system health
#
echo -en "/dev/sda "
smartctl --health /dev/sda | grep -o '\(SMART .*: [a-zA-Z]*\)'
echo -en "/dev/sdb "
smartctl --health /dev/sdb | grep -o '\(SMART .*: [a-zA-Z]*\)'

#
# inform user what we are about to output
#
echo ""
echo "   +-------------------------------------------------------------+   "
echo "   | MDADM STATUS                                                |   "
echo "   | (boot,system,www,swap drive, raid 1,1,0,0, using mdstat)    |   "
echo "   +-------------------------------------------------------------+   "
echo ""

#
# output intel raid info
#
cat /proc/mdstat

#
# inform user what we are about to output
#
echo ""
echo "   +-------------------------------------------------------------+   "
echo "   | ADAPTEC RAID BENCHMARK                                      |   "
echo "   | (storage drive, raid 60, using hdparm)                      |   "
echo "   +-------------------------------------------------------------+   "

#
# benchmark storage disk
#
hdparm -tT /dev/sdc

#
# inform user what we are about to output
#
echo ""
echo "   +-------------------------------------------------------------+   "
echo "   | ADAPTEC RAID DISK HEALTH                                    |   "
echo "   | (storage drive, raid 60, using smartctl)                    |   "
echo "   +-------------------------------------------------------------+   "
echo ""

#
# do system health
#
for i in `seq 3 15`; do
  echo -en "/dev/sg${i} "
  smartctl --health /dev/sg${i} | grep -o '\(SMART .*: [a-zA-Z]*\)'
done

#
# inform user what we are about to output
#
echo ""
echo "   +-------------------------------------------------------------+   "
echo "   | ADAPTEC RAID BENCHMARK                                      |   "
echo "   | (web drive, raid 1, using hdparm)                           |   "
echo "   +-------------------------------------------------------------+   "

#
# benchmark storage disk
#
hdparm -tT /dev/sdd

#
# inform user what we are about to output
#
echo ""
echo "   +-------------------------------------------------------------+   "
echo "   | ADAPTEC RAID DISK HEALTH                                    |   "
echo "   | (web drive, raid 1, using smartctl)                         |   "
echo "   +-------------------------------------------------------------+   "
echo ""

#
# do system health
#
for i in `seq 16 17`; do
  echo -en "/dev/sg${i} "
  smartctl --health /dev/sg${i} | grep -o '\(SMART .*: [a-zA-Z]*\)'
done

#
# inform user what we are about to output
#
echo ""
echo "   +-------------------------------------------------------------+   "
echo "   | ADAPTEC RAID STATUS                                         |   "
echo "   | (controller 1, using arcconf)                               |   "
echo "   +-------------------------------------------------------------+   "
echo ""

#
# show any tasks
#
arcconf getstatus 1

#
# inform user what we are about to output
#
echo ""
echo "   +-------------------------------------------------------------+   "
echo "   | ADAPTEC RAID INFO                                           |   "
echo "   | (controller 1, using arcconf)                     |   "
echo "   +-------------------------------------------------------------+   "
echo ""

#
# output intel raid info
#
arcconf getconfig 1

#
# clean exit
#
exit 0

#
# EOF
#
