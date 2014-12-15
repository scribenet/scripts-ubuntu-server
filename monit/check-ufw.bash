#!/bin/bash

##
## Scribe Inc
## Check if ufw is initialized and running
##

## Get the script output and return value
OUTPUT=$(/lib/ufw/ufw-init status)
RETURN=$?

## Output the command output
echo $OUTPUT

## Exit with return value of command
exit $RETURN

## EOF
