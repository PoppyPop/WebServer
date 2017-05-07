#!/bin/bash
#

wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
sudo dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb

sudo apt-get update

sudo apt-get install percona-xtrabackup

sudo rm -rf percona-release_0.1-4.$(lsb_release -sc)_all.deb