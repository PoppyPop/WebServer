#!/bin/bash
#

sudo mkdir -p /srv/scripts
sudo mkdir -p /srv/backs

sudo cp -rf scripts/* /srv/scripts/

sudo cp -rf cron.daily/* /etc/cron.daily/

sudo /srv/scripts/mariadb/install.sh
