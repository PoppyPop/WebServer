#!/bin/bash
#

# delete server file older than 7days
sudo rclone --min-age 7d delete gdsecret:$(hostname -f)

sudo rclone copy /srv/backs/ gdsecret:$(hostname -f)

if [ $? -eq 0 ] 
then
	echo "Sync complete"
fi
