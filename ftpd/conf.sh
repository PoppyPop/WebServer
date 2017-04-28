#!/bin/bash
#

echo "/bin/false" >> /etc/shells

echo "yes" > /etc/pure-ftpd/conf/ChrootEveryone

echo "57000 58000" > /etc/pure-ftpd/conf/PassivePortRange

systemctl restart pure-ftpd