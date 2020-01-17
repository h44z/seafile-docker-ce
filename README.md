[![Build Status](https://secure.travis-ci.org/haiwen/seafile-docker.png?branch=master)](http://travis-ci.org/haiwen/seafile-docker)

## About

- [Docker](https://docker.com/) is an open source project to pack, ship and run any Linux application in a lighter weight, faster container than a traditional virtual machine.

- Docker makes it much easier to deploy [a Seafile server](https://github.com/haiwen/seafile) on your servers and keep it updated.

- The base image configures Seafile with the Seafile team's recommended optimal defaults.

If you are not familiar with docker commands, please refer to [docker documentation](https://docs.docker.com/engine/reference/commandline/cli/).

## Building the docker image
To build the docker image, docker must be installed (at least version 17.06.0). 

You also need docker-squash (https://github.com/goldmann/docker-squash):
```
sudo pip3 install docker-squash
```

After the dependcies have been set up, change to the image directory and build the images using make:

```
make base
make server
```

## Running Seafile 7.x.x with docker-compose
TODO

### Troubleshooting

You can run docker commands like "docker logs" or "docker exec" to find errors.

```sh
docker logs -f seafile
# or
docker exec -it seafile bash
```
