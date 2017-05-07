#!/bin/bash
#

username=bkpuser
password=$(cat password.key)
datadir=/var/lib/mysql/
conf=/etc/mysql/my.cnf

now=`date +"%Y-%m-%d_%H-%M"`
backupdir=/srv/backs/mariadb

# Test Folder
if [ ! -d "$backupdir" ]; then
  mkdir -p $backupdir
fi

# First: Remove old backups
find $backupdir/ -type f -mtime +7 -delete

# Create the Backup
# export PATH=$PATH:/path/to/xtrabackup
# innobackupex --slave-info --user=$username --password=$password --no-timestamp /path/to/backupdir/db.$now 1>/path/to/backupdir/db.$now.log 2>&1
xtrabackup \
    --defaults-file=$conf \
    --host=127.0.0.1 --port=3306 \
    --user=$username --password=$password \
    --datadir=$datadir \
    --backup --target_dir=$backupdir/$now 1> $backupdir/$now.log 2>&1

	#--compress \
    #--compress-threads=4 \

# Prepare the Backup
if [ $? -eq 0 ]
then
        xtrabackup --prepare --target_dir=$backupdir/$now 1>> $backupdir/$now.log 2>&1
else
    echo "Mariadb: Fail"  
    exit 1  
fi

# Prepare the Backup
if [ $? -eq 0 ]
then
    #tar/compress result 
    tar -zcf $backupdir/$now.tar.gz \
       -C $backupdir \
       $now
    
    rm -rf $backupdir/$now
    
    echo "Mariadb: Ok"
else
    echo "Mariadb: Fail"    
fi



