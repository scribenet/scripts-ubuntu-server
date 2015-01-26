# Ubuntu Server: Helper Scripts

This repository contains a collection of helper scripts specifically created and solely tested on Ubuntu Server releases 14.04, 14.10, and 15.04. They include an array of shell scripts used by [Scribe Inc.](https://scribenet.com) to help with daily maintenance of our server infrastructure.

The included scripts, including a basic description of their use, is as follows:

- `dl/`

      - `update-geolitecity-db.bash`
      
        Useful as a stand-alone command or a cron job to update youu GeoLite database.

- `gitlab/`

    - `backup-config.bash`
     
      Called by rsnapshot to backup the current GitLab config each time a new 
      snapshot is created.
    
- `monit/`

    - `check-uwf.bash`
  
    Called by monit to determine the status of UFW. Returns a simple status string 
    and an exit value describing the firewall's up or down state.

- `mysql/`

    - `backup-databases-as-hot.bash`
    
      Uses innobackupex to perform an on-line (hot) backup of MySQL.
    
    - `backup-databases-to-sql.bash`
  
      Uses mysqldump to perform an SQL backup of each database (used as an rsnapshot 
      backup_script during a snapshot run).
    
    - `mysql-defragment.bash`
  
      Runs through all MySQL tables, attempts to determine fragmentation state, and 
      runs the native defragment command on each table deemed fragmented.
    
    - `perform-gstorage-bashup.bash`
  
      Wrapper around `backup-databases-as-hot.bash` and `backup-databases-to-
      sql.bash` that then uses Google Cloud storage to upload the resulting hot and 
      SQL-based backups.
    
- `piwik/`

    - `piwik-import-nginx-logs.bash`
  
      Wrapper around Piwik's `import_logs.py` that allows for the command to fail (as it often does) and then continues the import at the last offset.
    
- `rsnapshot/`

    - `rsnapshot-plugin-btrfs-cp.sh`
  
      Can be used as an alternative to `rsnapshot`'s native `cp` command on `btrfs` 
      filesystems (not well-tested; use with caution).

    - `rsnapshot-plugin-btrfs-rm.sh`
  
      Can be used as an alternative to `rsnapshot`'s native `rm` command on `btrfs`
      filesystems (not well-tested; use with caution).
    
- `system/`

    - `restart-network-interfaces.bash`
  
      With the removal of `/etc/init.d/networking` as a useful means of bringing the 
      network `up`/`down` on Ubuntu versions after `12.10`, this script brings back 
      that functionality in an SSH-safe manner.
    
    - `security-check-users-and-groups.bash`
  
      Validates that users and groups are correctly implemented in shadow files.
    
    - `toggle-web-maintenance-mode.bash`
  
      Toggles our website between a maintensnace mode and an online mode.
    
## License

These scripts are written for internal use at [Scribe Inc.](https://scribenet.com)
and are distributed without any warrenty as to their fitness or functionality.

All files within this repository are licensed under the [MIT License](LICENSE.md)
unless otherwise explicitly noted. Please see the [LICENSE.md](LICENSE.md) file 
for the complete license text.