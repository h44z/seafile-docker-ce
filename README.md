# Seafile Community Edition - Simple and Clean Docker Version

## About

Previously, this repository included a comprehensive Docker image for Seafile Server CE 11. 
It now provides only a docker-compose.yml file to facilitate deployment of the official Seafile Docker containers. 
The key differences from the official installation method are:

 - A single docker-compose.yml file is used
 - Traefik replaces Caddy as reverse proxy
 - SeaDoc, Metadata Server, Thumbnail Server and Seafile AI extension are omitted
 - Seafile Notification Server is included
 - OnlyOffice Document Server is included
 - Compatible with previous deployments of `h44z/seafile-ce` containers


## Running Seafile 13.x with Docker Compose

Starting from version 12, this repository uses the official Seafile Docker images.

Make sure that you have installed Docker Compose with version 2.30.0 or higher. Setting up Seafile is really easy and can be (or should be) done via Docker Compose. 
All important data is stored under `/shared` so you should be mounting a volume there (recommended), as shown in the example configurations, or at the respective subdirectories.

The first step is to create a `.env` file by copying the provided .env.dist file:
```bash
cp .env.dist .env
```
**Mandatory ENV variables for auto setup**

* **SEAFILE_SERVER_HOSTNAME**: Hostname of your Seafile installation, together with *SEAFILE_SERVER_PROTOCOL* the base-URL is derived
* **SEAFILE_SERVER_PROTOCOL**: either `http` or `https`
* **INIT_SEAFILE_ADMIN_EMAIL**: E-mail address of the Seafile admin
* **INIT_SEAFILE_ADMIN_PASSWORD**: Password of the Seafile admin
* **REDIS_PASSWORD**: Password for the Redis cache

If you want to use MySQL/MariaDB, the following variables are needed:

**Mandatory ENV variables for MySQL/MariaDB**
* **DB_HOST**: Address of your MySQL server
* **DB_USER**: MySQL user Seafile should use
* **DB_PASSWORD**: Password for said MySQL User
* **DB_PORT**: Port MySQL runs on (Optional, default 3306)

**Optional ENV variables for auto setup with MySQL/MariaDB**
* **MYSQL_USER_HOST**: Host the MySQL User is allowed from (default: '%')
* **DB_ROOT_PASSWD**: If you haven't set up the MySQL tables by yourself, Seafile will do it for you when being provided with the MySQL root password

A sample docker-compose file is provided within this repository.

For a clean install, only office might throw an error (mounting directory onto a file). If that happens ensure that the mount point already exists on the host system (see https://manual.seafile.com/deploy/only_office/ for details):

```bash
mkdir -p data/onlyoffice
cp sample-configs/local.json data/onlyoffice/local.conf
```

Custom settings to Docker containers can be added using a `docker-compose.override.yml` file. For example:

```yaml
services:
  db:
    image: mariadb:10.11 
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWD}
      - MYSQL_USER=${DB_USER}
      - MYSQL_PASSWORD=${DB_PASSWORD}
      - MYSQL_LOG_CONSOLE=true
      # - MARIADB_AUTO_UPGRADE=1
    volumes:
      - ./data/custom_db_backup:/tmp/dbbackup
  reverse-proxy:
    labels:
      - traefik.http.middlewares.dashboard-auth.basicauth.users=admin:$$2y$$05$$HndX02RYOlvwmPCMAXOyVe7VVnICX7czh7heoOYkf3lS/lByMA2hC # overrides the default credentials for the traefik dashboard
```

## Upgrading from Seafile 12.x

In Seafile 13, a few more configuration options and services were added. For most new values, the defaults should be sufficient. 
The only option that should manually be set in the `.env` file is `REDIS_PASSWORD`.

 - `SEAFILE_IMAGE_VERSION` was replaced with `SEAFILE_IMAGE`. `SEAFILE_IMAGE` now contains the whole image path, not just the version.
 - The Seafile notification server has been added. It is enabled with the `ENABLE_NOTIFICATION_SERVER` configuration option. The image can be specified using the `NOTIFICATION_SERVER_IMAGE` option.
 - Memcached was replaced with Redis. Therefore, the following new configuration options can be set: `CACHE_PROVIDER`, `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`.
   The most important option is `REDIS_PASSWORD`, specify a secure password here.

As documented in the [official upgrade guidelines](https://manual.seafile.com/latest/upgrade/upgrade_docker/#upgrade-from-120-to-130), you should also clean up old configuration values in `seafile.conf` and `seahub_settings.py`.

1. backup old files:

```shell
# please replace ./data to your $SEAFILE_SHARED_DATA
cp ./data/seafile/conf/seafile.conf ./data/seafile/conf/seafile.conf.bak_v12
cp ./data/seafile/conf/seahub_settings.py ./data/seafile/conf/seahub_settings.py.bak_v12
```

2. Clean up redundant configuration items in the configuration files:

Open `./data/seafile/conf/seafile.conf` and remove the entire `[memcached]`, `[database]`, `[commit_object_backend]`, `[fs_object_backend]`, `[notification]` and `[block_backend]` if above sections have correctly specified in .env.
Open `./data/seafile/conf/seahub_settings.py` and remove the entire blocks for `DATABASES = {...}` and `CAHCES = {...}`.

In the most cases, the `seafile.conf` then only include the listen port 8082 of Seafile file server.

## Upgrading from Seafile 11.x

Seafile 11.x used different Docker Images. Thus it is important to adapt the configuration variables in your `.env` file accordingly:

 - `MYSQL_SERVER` is now `DB_HOST`
 - `MYSQL_USER` is now `DB_USER`
 - `MYSQL_USER_PASSWORD` is now `DB_PASSWORD`
 - `MYSQL_PORT` is now `DB_PORT`
 - `MYSQL_ROOT_PASSWORD` is now `DB_ROOT_PASSWD`
 - `SEAFILE_VERSION` is now `SEAFILE_IMAGE_VERSION`  (This is a very important change - Seafile does not start correctly with the old parameter!)
 - `SEAFILE_NAME` is removed
 - `SEAFILE_ADDRESS` is now a combination of `SEAFILE_SERVER_PROTOCOL` and `SEAFILE_SERVER_HOSTNAME`
 - `SEAFILE_ADMIN` is now `INIT_SEAFILE_ADMIN_EMAIL`
 - `SEAFILE_ADMIN_PW` is now `INIT_SEAFILE_ADMIN_PASSWORD`
 - `LDAP_IGNORE_CERT_CHECK` is removed
 - `MODE` is removed

New environment variables were added as well:

 - `JWT_PRIVATE_KEY`: Use the existing token from seafile.conf (`jwt_private_key`)
 - `ENABLE_SEADOC`: Check official seafile docs, can be kept default
 - `SEAFILE_LOG_TO_STDOUT`: Check official seafile docs, can be kept default
 - `NON_ROOT`: Check official seafile docs, can be kept default
 - `SITE_ROOT`: Check official seafile docs, can be kept default

Besides the adaption of configuration variables, it is also important to move the `current_version` file to a new location. Without this step, upgrading Seafile might fail which renders your instance unusable!

`mv ./data/seafile/current_version ./data/seafile/seafile-data/current_version`


## Upgrading from Seafile 11.0.5
Starting from 11.0.6, this repository uses Traefik v2 as reverse proxy for Seafile and OnlyOffice. Therefore, other reverse proxies like Nginx should be disabled to avoid port binding conflicts.
The `.env` configuration must also be updated to include a **DOMAINNAME** variable which contains the top-level domain name of your Seafile instance. The seafile server will be reachable on the subdomain **https://seafile.[DOMAINNAME]**.

## Upgrading from Seafile 10.x.x
Simply use the newer 11.x.x Docker image. If you used LDAP, please follow the [official upgrade instructions](https://manual.seafile.com/upgrade/upgrade_notes_for_11.0.x/) and update the settings accordingly.

## Upgrading from Seafile 9.x.x
Simply use the newer 10.x.x Docker image and enable the notification server in your seafile.conf.
To enable the notification server, follow the [official documentation](https://manual.seafile.com/config/seafile-conf/#notification-server-configuration).


## Upgrading from Seafile 8.x.x
Simply use the newer 9.x.x Docker image.


## Upgrading from Seafile 7.x.x
This version of the image is designed to work with version 9.x.x.
The previous version of this Docker image was based on the official Docker image, thus a few changes have to be made in order to upgrade to the new version.

Changes:
 - Nginx and Letsencrypt are no longer included in the image.
 - The log directory is no longer included in the main directory that can be exported using volumes.
 - The path of the main directory changed from `/shared` to `/seafile`.
 - The file holding the current seafile version now lives in `/seafile/current_version` instead of `/shared/seafile-data/current_version`.
 - Many environment variables have been removed in order to keep this image and the setup script simple. Special customizations can still be achived, see [here](#manual-configuration-of-seafile).


### Environment Variables
Take a look at .env.dist for all available environment variables. Copy `.env.dist` to `.env`, uncomment and edit the variables as needed.


### Manual configuration of Seafile
After the Seafile container has been started at least once, the mounted volume for the `/seafile` directory should contain a folder `conf`. Take a look at the official manual to check out which settings can be changed.

**HINT**: After the initial setup (first run), changing the environment variables in .env does not reflect to the configuration files!


### Troubleshooting

You can run docker commands like "docker logs" or "docker exec" to find errors.

```sh
docker logs -f seafile
# or
docker exec -it seafile bash
```
