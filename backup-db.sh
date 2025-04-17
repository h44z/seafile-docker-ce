#!/bin/bash

SCRIPT_DIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
cd $SCRIPT_DIR

set -a; source .env; set +a

mkdir -p dbbackup

echo "Performing backup..."

docker compose exec db mysqldump -u root --password=$DB_ROOT_PASSWD --single-transaction --routines ccnet_db > dbbackup/ccnet.sql
docker compose exec db mysqldump -u root --password=$DB_ROOT_PASSWD --single-transaction --routines seafile_db > dbbackup/seafile.sql
docker compose exec db mysqldump -u root --password=$DB_ROOT_PASSWD --single-transaction --routines seahub_db > dbbackup/seahub.sql

echo "DB backup finished - check output"
