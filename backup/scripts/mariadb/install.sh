#!/bin/bash
#

src=${BASH_SOURCE%/*}

if [ ! -f $src/password.key ] 
then 
	databasePassword=$(openssl rand -base64 16)

	echo $databasePassword > $src/password.key 

	chmod g-w,o-rwx $src/password.key

	echo "CREATE USER 'bkpuser'@'%' IDENTIFIED BY '$databasePassword';GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT, CREATE TABLESPACE, PROCESS, SUPER ON *.* TO 'bkpuser'@'%';GRANT CREATE, INSERT, SELECT ON PERCONA_SCHEMA.* TO 'bkpuser'@'%';FLUSH PRIVILEGES;" | mysql -u root -p
fi