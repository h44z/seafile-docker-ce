.SILENT:

PREPARE := $(shell test -e ../.env || cp ../.env.dist ../.env)
IS_ENV_PRESENT := $(shell test -e ../.env && echo -n yes)
GIT_HASH := $(shell git rev-parse --short HEAD)

ifeq ($(IS_ENV_PRESENT), yes)
	include ../.env
	export $(shell sed 's/=.*//' ../.env)
endif

server_image=h44z/seafile-ce:${SEAFILE_VERSION}
latest_server_image=h44z/seafile-ce:latest

all:
	@echo
	@echo Pleaes use '"make server"' or '"make push"'.
	@echo

server:
	@echo Building seafile server version ${SEAFILE_VERSION}
	cd seafile && docker build --no-cache -t $(server_image) . --build-arg SEAFILE_VERSION=${SEAFILE_VERSION}

push-server:
	docker tag $(server_image) $(latest_server_image)
	docker tag $(server_image) $(server_image)-$(GIT_HASH)
	docker push $(server_image)-$(GIT_HASH)
	docker push $(latest_server_image)

push-server-release:
	docker tag $(server_image) $(server_image)
	docker push $(server_image)

push: push-server push-server-release

.PHONY: server push push-release push-server push-server-release
