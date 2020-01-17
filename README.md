[![Build Status](https://secure.travis-ci.org/haiwen/seafile-docker.png?branch=master)](http://travis-ci.org/haiwen/seafile-docker)

## About

- This repository contains the sources that are used to build the `h44z/seafile-ce` docker image.

- It is based on the official docker image (https://github.com/haiwen/seafile-docker). 

- The image only contains the community edition of seafile. The build process has been simplified and improved in comparison to the official image.

- It is possible to use this image with an existing, none dockerized Seafile installation. The usage of an external reverse proxy (like nginx) is also supported.

- Setting up is really easy and can be (or should be) done via Docker Compose.


## Building the docker image from scratch
To build the docker image, docker must be installed (at least version 17.06.0). 

After the dependcies have been set up, change to the image directory and build the images using make:

```
# get the sources
git clone https://github.com/h44z/seafile-docker.git
cd seafile-docker/image

# build the image
make base
make server
```

## Running Seafile 7.x.x with docker-compose
Make sure that you have installed Docker Compose with version 1.19.0 or higher.

```
# get the sources
git clone https://github.com/h44z/seafile-docker.git
cd seafile-docker

# configure the environment, change seafile settings
cp .env.dist .env
edit .env

# start it!
docker-compose up

# have fun...
```

### Troubleshooting

You can run docker commands like "docker logs" or "docker exec" to find errors.

```sh
docker logs -f seafile
# or
docker exec -it seafile bash
```
