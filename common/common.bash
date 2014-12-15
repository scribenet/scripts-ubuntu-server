#!/bin/bash

##
## Scribe Inc
## Include any common files
##
## @author Rob Frawley 2nd <rmf@scribe.tools>
##

## Where are we?
DIR_COMMON="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

## Include init script
source ${DIR_COMMON}/init.bash

## Include functions script
source ${DIR_COMMON}/functions.bash

## EOF
