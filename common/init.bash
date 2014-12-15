#!/bin/bash

##
## Scribe Inc
## Collections of initializer checks for our bash scripts library
##
## @author Rob Frawley 2nd <rmf@scribe.tools>
##

## Perform sanity check that bash is being used to call script
if [ -z "$BASH_VERSION" ]
then
    echo "This script can only be run with bash. Exiting."
    exit 4
fi
