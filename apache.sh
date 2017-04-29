#!/bin/bash
#

a2enmod expires
a2enmod headers
a2enmod ext_filter

apt-get install php5-apcu
# Disable current cache
nano /etc/php5/apache2/conf.d/05-opcache.ini
