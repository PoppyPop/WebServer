#!/bin/bash
#

src=${BASH_SOURCE%/*}

# BDD
echo "Backup Bdd"
${src}/mariadb/backup-mariadb.sh

# Web
echo "Web"
${src}/web/backup-web.sh

# End : Sync to gdrive
echo "GSync"
${src}/gdrive-sync.sh

# Clean BDD
echo "Clean Bdd"
${src}/mariadb/clean-mariadb.sh

# clean Web
echo "Clean Web"
${src}/web/clean-web.sh