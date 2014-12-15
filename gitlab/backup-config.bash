#!/bin/bash

##
## Scribe Inc
## Back up GitLab config and database
##

## Per https://gitlab.com/gitlab-org/omnibus-gitlab/blob/7-1-stable/README.md#backup-and-restore-omnibus-gitlab-configuration
sh -c 'umask 0077; tar -cf $(date "+etc-gitlab-%s.tar") -C / etc/gitlab'

