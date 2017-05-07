#!/bin/bash
#

backupdir=/srv/backs/web
backupsrc=/srv/www
now=`date +"%Y-%m-%d_%H-%M"`

# Test Folder
if [ ! -d "$backupdir" ]; then
  mkdir -p $backupdir
fi

# First: Remove old backups
find $backupdir/ -type f -mtime +7 -delete

cd $backupsrc

# Add New Backup
for i in */; do tar -zcf $backupdir/${i%/}-$now.tar.gz -C $backupsrc/$i .; done

cd -

# Add New Backup
# tar -zcf $backupdir/$now.tar.gz -C $backupsrc .