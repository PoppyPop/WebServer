#!/bin/bash

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

if [ "$action" != 'create' ] && [ "$action" != 'disable' ] && [ "$action" != 'delete' ]
	then
		echo $"You need to prompt for action (create or delete) -- Lower-case only"
		exit 1;
fi

while [ "$domain" == "" ]
do
	echo -e $"Please provide domain. e.g.example.com"
	read domain
done

if [ "$priority" == "" ] 
	then
		priority=99
fi

#Sanitize domain case
domain=$(echo "$domain" | tr '[:upper:]' '[:lower:]')

siteName=$priority-$domain.conf
sitesAvailabledomain=$sitesAvailable$siteName
rootDir=$userDir$domain
email="webmaster@$domain"
owner=$(echo "$domain" | sed 's~[^[:alnum:]/]\+~~g')

userindex=0
while id "$owner" >/dev/null 2>&1; do
	owner=$owner$userindex
	userindex=$(( userindex + 1 ))
done

echo "====== Configuration ======"
echo "Action    : $action"
echo "Domain    : $domain"
echo "Priority  : $priority"
echo "Conf File : $sitesAvailabledomain"
echo "Root Dir  : $rootDir"
echo "Email     : $email"
echo "Sys User  : $owner"

while true; do
    read -p "Do you wish to commit this configuration?" yn
    case $yn in
        [Yy]* ) break;break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "Yes"
exit;

if [ "$action" == 'create' ]
	then
		### check if domain already exists
		if [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain already exists.\nPlease Try Another one"
			exit;
		fi
		
		### Create User
		adduser --system --group --home $rootDir $owner

		### check if directory exists or not
		if ! [ -d $rootDir ]; then
			### create the directory
			mkdir $rootDir
			
			### create subdirectory (data and logs
			mkdir $rootDir/web
			mkdir $rootDir/logs
			mkdir $rootDir/ssl
			
			### give permission to root dir (A+R)
			chmod 700 $rootDir
			
			### write test file in the new domain dir
			if ! echo "<?php echo phpinfo(); ?>" > $rootDir/web/phpinfo.php
			then
				echo $"ERROR: Not able to write in file $rootDir/phpinfo.php. Please check permissions"
				exit;
			else
				echo $"Added content to $rootDir/phpinfo.php"
			fi
			
			### give permission to subdirectory (A+RX)
			chmod 740 $rootDir/web
			chmod 740 $rootDir/logs
			chmod 740 $rootDir/ssl
			
			### change user
			chown -R $owner:$owner $rootDir
		fi

		### create virtual host rules file
		if ! echo "
		<Directory $rootDir>
			AllowOverride None
			Order Deny,Allow
			Deny from all
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

		</VirtualHost>" > $sitesAvailabledomain
		then
			echo -e $"There is an ERROR creating $domain file"
			exit;
		else
			echo -e $"\nNew Virtual Host Created\n"
		fi

		### enable website
		a2ensite $siteName

		### restart Apache
		systemctl reload apache2

		### show the finished message
		echo -e $"Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $rootDir"
		
	elif [ "$action" == 'disable' ]
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit;
		fi
		
		### disable website
		a2dissite $siteName
		
		### reload Apache
		systemctl reload apache2
		
		### show the finished message
		echo -e $"Complete! \n$siteName has been disabled"
		
	elif [ "$action" == 'delete' ]
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit;
		fi
		
		### disable website
		a2dissite $siteName
		
		### reload Apache
		systemctl reload apache2
		
		### Delete virtual host rules files
		rm $sitesAvailabledomain	
		
		### check if directory exists or not
		if [ -d $rootDir ]; then
		
			sysuser=$(ls -ld $rootDir | awk '{print $3}')
			
			deluser --system --group --remove-home $sysuser
			deluser --system --remove-home $sysuser
		
			echo -e $"Directory deleted"
		else
			echo -e $"Host directory not found. Unable to delete the user"
		fi	
		
		### show the finished message
		echo -e $"Complete!\nYou just removed Virtual Host $siteName"
		exit 0;
		
	else
		### show the finished message
		echo -e $"UNKNOWN"
		exit 0;
fi