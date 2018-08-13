#!/bin/bash

### Requirements
source /etc/apache2/envvars

### functions

function setVirtualHostConfFile {
	### create virtual host rules file
	if ! echo "
	<Directory $rootDir>
		AllowOverride None
		Require all denied
	</Directory>
		
	<VirtualHost *:80>
		ServerAdmin $email
		ServerName $domain
		ServerAlias *.$domain
		DocumentRoot $rootDir/web
				
		# Possible values include: debug, info, notice, warn, error, crit,
		# alert, emerg.
		LogLevel warn

		CustomLog $rootDir/logs/access.log combined
		ErrorLog  $rootDir/logs/error.log
		
		<Directory $rootDir/web>
			Options +FollowSymLinks
			AllowOverride all
			Require all granted
		</Directory>
		
		# suexec enabled
		<IfModule mod_suexec.c>
			SuexecUserGroup $owner $owner
		</IfModule>
		
		# add support for apache mpm_itk
		<IfModule mpm_itk_module>
			AssignUserId $owner $owner
		</IfModule>

	</VirtualHost>
	<VirtualHost *:443>
		ServerAdmin $email
		ServerName $domain
		ServerAlias *.$domain
		DocumentRoot $rootDir/web
				
		# Possible values include: debug, info, notice, warn, error, crit,
		# alert, emerg.
		LogLevel warn

		CustomLog $rootDir/logs/access.log combined
		ErrorLog  $rootDir/logs/error.log
		
		<Directory $rootDir/web>
			Options +FollowSymLinks
			AllowOverride all
			Require all granted
		</Directory>
		
		# suexec enabled
		<IfModule mod_suexec.c>
			SuexecUserGroup $owner $owner
		</IfModule>
		
		# add support for apache mpm_itk
		<IfModule mpm_itk_module>
			AssignUserId $owner $owner
		</IfModule>
		
		<IfModule mod_ssl.c>
			SSLEngine on
			SSLProtocol All -SSLv2 -SSLv3
			SSLCertificateFile $rootDir/ssl/$domain.crt
			SSLCertificateKeyFile $rootDir/ssl/$domain.key
		</IfModule>

	</VirtualHost>" > $1
	then
		echo -e $"There is an ERROR creating $domain file"
		exit;exit 4;
	else
		echo -e $"New Virtual Host Created"
	fi
}

function setLogRotateConfFile {
	### create virtual host rules file
	if ! tee $1 &>/dev/null <<EOF
$rootDir/logs/*.log {
	daily
	missingok
	rotate 14
	compress
	delaycompress
	notifempty
	create 640 root adm
	sharedscripts
	postrotate
		if /etc/init.d/apache2 status > /dev/null ; then \
			/etc/init.d/apache2 reload > /dev/null; \
		fi;
	endscript
	prerotate
		if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
			run-parts /etc/logrotate.d/httpd-prerotate; \
		fi; 
	endscript
}
EOF
	then
		echo -e $"There is an ERROR creating $domain logrotate file"
		exit;exit 4;
	else
		echo -e $"LogRotate Created"
	fi
}

function genCrt {

	rootDir=$1
	domain=$2
	owner=$3
	
	openssl req -x509 -newkey rsa:4096 -days 3650 -sha256 -nodes \
			-subj "/C=FR/ST=FR/L=Paris/O=$owner/CN=$domain" \
			-reqexts SAN \
			-extensions SAN \
			-config <(cat /etc/ssl/openssl.cnf \
				<(printf "\n[SAN]\nsubjectAltName=DNS:*.$domain")) \
			-keyout $rootDir/ssl/$domain.key -out $rootDir/ssl/$domain.crt
			
	chown $owner:$owner $rootDir/ssl/$domain.key
	chown $owner:$owner $rootDir/ssl/$domain.crt
}

### Set default parameters
action=$1
domain=$2
priority=$3
sitesEnable='/etc/apache2/sites-enabled/'
sitesAvailable='/etc/apache2/sites-available/'
userDir='/srv/www/'

### don't modify from here unless you know what you are doing ####

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Use sudo"
		exit 1;
fi

while [ "$domain" == "" ]
do
	echo -e $"Please provide domain. e.g.example.com"
	read domain
done

if [ "$priority" == "" ]; then
		priority=99
fi

#Sanitize domain case
domain=$(echo "$domain" | tr '[:upper:]' '[:lower:]')

siteName=$priority-$domain.conf
sitesAvailabledomain=$sitesAvailable$siteName
rootDir=$userDir$domain
logrotateConf=/etc/logrotate.d/$domain
email="webmaster@$domain"
owner=$(echo "$domain" | sed 's~[^[:alnum:]/]\+~~g')
owner=${owner:0:15}

echo "====== Configuration ======"
echo "Action    : $action"
echo "Domain    : $domain"
echo "Priority  : $priority"
echo "Conf File : $sitesAvailabledomain"
echo "Root Dir  : $rootDir"
echo "Email     : $email"


if [ "$action" == 'create' ]
	then
		### check if domain already exists
		if [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain already exists.\nPlease Try Another one"
			exit 2;
		fi
		
		userindex=0
		while id "$owner" >/dev/null 2>&1; do
			owner=$owner$userindex
			userindex=$(( userindex + 1 ))
		done
		echo "Sys User  : $owner"
		
		while true; do
		    read -p "Do you wish to commit this configuration?" yn
    		case $yn in
        		[Yy]* ) break;break;;
        		[Nn]* ) exit;;
        		* ) echo "Please answer yes or no.";;
    		esac
		done
		
		generatedPassword=$(openssl rand -base64 12)

		### Create User
		adduser --system --group --home $rootDir $owner
		echo "$owner:$generatedPassword" | chpasswd

		### check if directory exists or not
		if ! [ -d $rootDir ]; then
			### create the directory
			mkdir $rootDir
		fi	
		
		### Forcing permission
		echo "umask 027" > $rootDir/.bashrc
		chown $owner:$owner $rootDir/.bashrc
		
		### create subdirectory (data and logs
		mkdir $rootDir/web
		mkdir $rootDir/logs
		mkdir $rootDir/ssl
		
		## Logs
		ln -s $rootDir/logs/access.log ${APACHE_LOG_DIR}/$domain-access.log
		ln -s $rootDir/logs/error.log ${APACHE_LOG_DIR}/$domain-error.log
						
		### change user
		chown root:$owner $rootDir
		chown root:$owner $rootDir/web
		chown root:$owner $rootDir/logs
		chown root:$owner $rootDir/ssl
		
		### give permission to subdirectory (A+RX)
		chmod 1750 $rootDir
		chmod 1770 $rootDir/web
		chmod 1770 $rootDir/logs
		chmod 1770 $rootDir/ssl
		
		### Create dummy certificate	
		genCrt $rootDir $domain $owner
		
		### write test file in the new domain dir
		if ! echo "<?php echo phpversion(); ?>" > $rootDir/web/phpversion.php
		then
			echo $"ERROR: Not able to write in file $rootDir/phpversion.php. Please check permissions"
			exit 3;
		else
			echo $"Added content to $rootDir/phpversion.php"
		fi
		
		chown $owner:$owner $rootDir/web/phpversion.php
		chmod 550 $rootDir/web/phpversion.php

		setVirtualHostConfFile $sitesAvailabledomain
		setLogRotateConfFile $logrotateConf
		
		### Create database
		databasePassword=$(openssl rand -base64 12)
		
		echo "create database $owner;" | mysql --defaults-file=mysql-client.conf
		echo "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,ALTER,INDEX,DROP ON $owner.* TO '$owner'@'localhost' IDENTIFIED BY '$databasePassword';" | mysql --defaults-file=mysql-client.conf

		echo -e $"=========== INFOS ==========="
		echo "Site     : http://$domain And http://*.$domain" 
		echo "==      Ftp      =="
		echo "Ftp      : ftp://$(hostname -f)"
		echo "User     : $owner"
		echo "Password : $generatedPassword"
		echo "==    Database   =="
		echo "Url      : https://$(hostname -f)/phpmyadmin"
		echo "User     : $owner"
		echo "Base     : $owner"
		echo "Password : $databasePassword"
		echo -e $"=========== INFOS ==========="

		### show the finished message
		echo -e $"Don't forget to enable it"
		
	elif [ "$action" == 'enable' ]; then
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit 2;
		fi
		
		### disable website
		a2ensite $siteName
		
		### reload Apache
		systemctl reload apache2
		
		### show the finished message
		echo -e $"Complete! \n$siteName has been enabled"	
		
	elif [ "$action" == 'disable' ]; then
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit 2;
		fi
		
		### disable website
		a2dissite $siteName
		
		### reload Apache
		systemctl reload apache2
		
		### show the finished message
		echo -e $"Complete! \n$siteName has been disabled"
		
	elif [ "$action" == 'delete' ]; then
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit 2;
		fi
		
		while true; do
		    read -p "Do you wish to commit this configuration?" yn
    		case $yn in
        		[Yy]* ) break;break;;
        		[Nn]* ) exit;;
        		* ) echo "Please answer yes or no.";;
    		esac
		done
		
		### disable website
		a2dissite $siteName
		
		### reload Apache
		systemctl reload apache2
		
		### Delete virtual host rules files
		rm $sitesAvailabledomain	
		
		### Delete logrotate
		rm $logrotateConf
		
		### check if directory exists or not
		if [ -d $rootDir ]; then
		
			sysuser=$(ls -ld $rootDir | awk '{print $4}')
			
			deluser --system --remove-home $sysuser
			#deluser --system --group --remove-home $sysuser
			
			rm -rf $rootDir
		
			echo -e $"Directory deleted"
			
			## BDD User

			echo "DROP USER '$sysuser'@'localhost';" | mysql --defaults-file=mysql-client.conf
			
		else
			echo -e $"Host directory not found. Unable to delete the user (sys, bdd)"
		fi	
		
		### Bdd File
		echo "drop database $owner;" | mysql --defaults-file=mysql-client.conf
		
		## Logs
		rm ${APACHE_LOG_DIR}/$domain-*
		
		### show the finished message
		echo -e $"Complete!\nYou just removed Virtual Host $siteName"
		exit 0;
	elif [ "$action" == 'conf' ]; then
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit 2;
		fi
		
		setVirtualHostConfFile $sitesAvailabledomain
		setLogRotateConfFile $logrotateConf
		
		### show the finished message
		echo -e $"Complete!\nYou just updated Virtual Host $siteName"
		exit 0;
	elif [ "$action" == 'renew' ]; then
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit 2;
		fi
		
		### Create dummy certificate	
		genCrt $rootDir $domain $owner
		
		### show the finished message
		echo -e $"Complete!\nYou just renewed Virtual Host $siteName"
		exit 0;
	else
		### show the finished message
		echo $"You need to prompt for action (create, enable, disable, conf or delete) -- Lower-case only"
		exit 1;
fi