#!/bin/bash

##
## Scribe Inc
## Perform consistency check on /etc/passwd to /etc/shadow and /etc/group to /etc/gshadow
##

pwck -r
grpck -r
