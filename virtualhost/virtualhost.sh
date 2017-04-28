#!/bin/bash

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
		ErrorLog $rootDir/logs/error.log
		
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
		ErrorLog $rootDir/logs/error.log
		
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
			#SSLEngine on
			#SSLProtocol All -SSLv2 -SSLv3
			#SSLCertificateFile $rootDir/ssl/$domain.crt
			#SSLCertificateKeyFile $rootDir/ssl/$domain.key
		</IfModule>

	</VirtualHost>" > $1
	then
		echo -e $"There is an ERROR creating $domain file"
		exit;exit 4;
	else
		echo -e $"New Virtual Host Created"
	fi
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
email="webmaster@$domain"
owner=$(echo "$domain" | sed 's~[^[:alnum:]/]\+~~g')



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
		echo "$generatedPassword" | passwd "$owner" --stdin

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
				
		### change user
		chown root:$owner $rootDir
		chown root:$owner $rootDir/web
		chown root:$owner $rootDir/logs
		chown root:$owner $rootDir/ssl
		
		### give permission to subdirectory (A+RX)
		chmod 1750 $rootDir
		chmod 1750 $rootDir/web
		chmod 1750 $rootDir/logs
		chmod 1750 $rootDir/ssl
		
		### write test file in the new domain dir
		if ! echo "<?php echo phpversion(); ?>" > $rootDir/web/phpversion.php
		then
			echo $"ERROR: Not able to write in file $rootDir/phpversion.php. Please check permissions"
			exit 3;
		else
			echo $"Added content to $rootDir/phpversion.php"
		fi
		
		chown $owner:$owner $rootDir/web/phpversion.php

		setVirtualHostConfFile $sitesAvailabledomain

		echo -e $"=========== INFOS ==========="
		echo "Site     : http://$domain And http://*.$domain" 
		echo "Ftp      : ftp://$(hostname -f)"
		echo "User     : $owner"
		echo "Password : $generatedPassword"
		echo -e $"=========== INFOS ==========="

		### show the finished message
		echo -e $"Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $rootDir"
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
		
		### check if directory exists or not
		if [ -d $rootDir ]; then
		
			sysuser=$(ls -ld $rootDir | awk '{print $3}')
			
			deluser --system --remove-home $sysuser
			deluser --system --group --remove-home $sysuser
			
			rml -rf $rootDir
		
			echo -e $"Directory deleted"
		else
			echo -e $"Host directory not found. Unable to delete the user"
		fi	
		
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
		
		### show the finished message
		echo -e $"Complete!\nYou just updated Virtual Host $siteName"
		exit 0;
	else
		### show the finished message
		echo $"You need to prompt for action (create, enable, disable, conf or delete) -- Lower-case only"
		exit 1;
fi