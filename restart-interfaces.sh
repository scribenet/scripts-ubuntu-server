#!/bin/bash

##
## Scribe Inc
## Bring eth0 down and up again
##

#
# this script can only be run by root
#
if [[ $EUID -ne 0 ]]; then

   echo "This script must be run as root. Try sudo." 1>&2
   exit 1

fi

#
# restart networking
#
echo -en "Restarting eth0:[1,2,3,4]...you may need to re-initiate your SSH connection..."
(ifdown --exclude=lo -a; ifup --exclude=lo -a)&
#(ifdown eth0 eth0:1 eth0:2 eth0:3 eth0:4 ; ifup eth0 eth0:1 eth0:2 eth0:3 eth0:4)&
echo "done."

#
# exit cleanly
#
exit 0

#
# EOF
#
