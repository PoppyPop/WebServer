#!/bin/bash
#

apt-get install apache2-suexec
apt-get install apache2-mpm-itk

databasePassword=$(openssl rand -base64 16)

cat > mysql-client.conf <<- EOM
[client]
user=virtualhost
password="$databasePassword"
EOM

chmod go-rwx mysql-client.conf

echo "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP, CREATE USER, USAGE ON *.* TO 'virtualhost'@'localhost' IDENTIFIED BY '$databasePassword' WITH GRANT OPTION;" | mysql -u root -p