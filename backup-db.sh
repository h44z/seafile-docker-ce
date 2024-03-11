#!/bin/bash

SCRIPT_DIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
cd $SCRIPT_DIR

set -a; source .env; set +a

mkdir -p dbbackup
mysqldump -u root --password=$MYSQL_ROOT_PASSWORD --single-transaction --routines ccnet_db > dbbackup/ccnet.sql
mysqldump -u root --password=$MYSQL_ROOT_PASSWORD --single-transaction --routines seafile_db > dbbackup/seafile.sql
mysqldump -u root --password=$MYSQL_ROOT_PASSWORD --single-transaction --routines seahub_db > dbbackup/seahub.sql

echo "DB backup finished - check output"
