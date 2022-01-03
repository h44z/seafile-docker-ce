# Seafile Community Edition - Simple and Clean Docker Version

[![Docker Stars](https://img.shields.io/docker/stars/h44z/seafile-ce.svg)](https://hub.docker.com/r/h44z/seafile-ce/)
[![Docker Pulls](https://img.shields.io/docker/pulls/h44z/seafile-ce.svg)](https://hub.docker.com/r/h44z/seafile-ce/)
[![Docker Build](https://img.shields.io/docker/automated/h44z/seafile-ce.svg)](https://hub.docker.com/r/h44z/seafile-ce/)

## About

- This repository contains the sources that are used to build the `h44z/seafile-ce` docker image. Currently tested with Seafile CE 9.0.2.

- The main goal of this image is to provide a really simple and clean docker image for Seafile Community Edition.
 The official docker image is quite complex and hard to extend or modify. This image instead provides a simple way to deploy a standardized Seafile instance with Docker.

- Automated features that come with this Docker image:
  - newest seafile version at rebuild
  - Automatically runs upgrade scripts (when pulling a newer image) provided by seafile
  - Configurable to run with MySQL/MariaDB or SQLite
  - Auto-setup at initial run
  - Supports different startup mode (MODE):
    - autorun: Default mode, setups server (if neccessary), upgrade database, then run server.
    - collect_garbage: Run garbage collector instead of starting server
    - diagnose: Run Seafile fsck to validate file consistency.
    - maintenance: Only start the container. You can log into it with docker exec and work on it.

- It is largly based on this docker image: https://github.com/Gronis/docker-seafile. 

## Building the docker image from scratch
To build the docker image, docker must be installed (at least version 18.02.0). 

After the dependcies have been set up, change to the image directory and build the images using make:

```
# get the sources
git clone https://github.com/h44z/seafile-docker.git
cd seafile-docker
cp .env.dist .env
edit .env  # if needed (for building, only the version is needed)

# build the image
cd image
make server
```


## Running Seafile 9.x.x with docker-compose
Make sure that you have installed Docker Compose with version 1.21.0 or higher. Setting up Seafile is really easy and can be (or should be) done via Docker Compose. All important data is stored under `/seafile` so you should be mounting a volume there (recommended), as shown in the example configurations, or at the respective subdirectories.

The first step is to create a `.env` file by copying the provided .env.dist file:
```bash
cp .env.dist .env
```
**Mandatory ENV variables for auto setup**

* **SEAFILE_NAME**: Name of your Seafile installation
* **SEAFILE_ADDRESS**: URL to your Seafile installation
* **SEAFILE_ADMIN**: E-mail address of the Seafile admin
* **SEAFILE_ADMIN_PW**: Password of the Seafile admin

If you want to use MySQL/MariaDB, the following variables are needed:

**Mandatory ENV variables for MySQL/MariaDB**
* **MYSQL_SERVER**: Address of your MySQL server
* **MYSQL_USER**: MySQL user Seafile should use
* **MYSQL_USER_PASSWORD**: Password for said MySQL User
* **MYSQL_PORT**: Port MySQL runs on (Optional, default 3306)

**Optional ENV variables for auto setup with MySQL/MariaDB**
* **MYSQL_USER_HOST**: Host the MySQL User is allowed from (default: '%')
* **MYSQL_ROOT_PASSWORD**: If you haven't set up the MySQL tables by yourself, Seafile will do it for you when being provided with the MySQL root password

Using the `MODE` environment variable, the startup behaviour of the container can be managed, defaults to *autorun*.

A sample docker-compose file is provided within this repository.

For a clean install, only office might throw an error (mounting directory onto a file). If that happens ensure that the mount point already exists on the host system (see https://manual.seafile.com/deploy/only_office/ for details):

```bash
mkdir -p data/onlyoffice
cp sample-configs/local.json data/onlyoffice/local.conf
```


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

HINT: After the initial setup (first run), changing the environment variables in .env does not reflect to the configuration files!


### Troubleshooting

You can run docker commands like "docker logs" or "docker exec" to find errors.

```sh
docker logs -f seafile
# or
docker exec -it seafile bash
```
