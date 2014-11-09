#!/bin/sh

# Arg 1: -al
# Arg 2: /testbtrfs/backups/hourly.0
# Arg 3: /testbtrfs/backups/hourly.1

btrfs subvolume snapshot $2 $3
