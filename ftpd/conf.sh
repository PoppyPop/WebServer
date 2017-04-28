#!/bin/bash
#

echo "/bin/false" >> /etc/shells

echo "yes" > /etc/pure-ftpd/conf/ChrootEveryone

systemctl restart pure-ftpd