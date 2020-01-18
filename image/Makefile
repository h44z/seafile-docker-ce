.SILENT:

PREPARE := $(shell test -e ../.env || cp ../.env.dist ../.env)
IS_ENV_PRESENT := $(shell test -e ../.env && echo -n yes)
GIT_HASH := $(shell git rev-parse --short HEAD)

ifeq ($(IS_ENV_PRESENT), yes)
	include ../.env
	export $(shell sed 's/=.*//' ../.env)
endif

server_version=${VERSION}

base_image=h44z/base-ce:18.04
latest_base_image=h44z/base-ce:latest
server_image=h44z/seafile-ce:$(server_version)
latest_server_image=h44z/seafile-ce:latest

all:
	@echo
	@echo Pleaes use '"make base"' or '"make server"' or '"make push"'.
	@echo

base:
	docker pull phusion/baseimage:0.11
	cd base && docker build --no-cache -t $(base_image) .
	
server:
	@echo Building seafile server version ${VERSION}
	cd seafile && docker build --no-cache -t $(server_image) . --build-arg SEAFILE_VERSION=${VERSION} \
		--build-arg LDAP_IGNORE_CERT_CHECK=${LDAP_IGNORE_CERT_CHECK}

push-base:
	docker tag $(base_image) $(latest_base_image)
	docker tag $(base_image) $(base_image)-$(GIT_HASH)
	docker push $(base_image)-$(GIT_HASH)
	docker push $(latest_base_image)

push-base-release:
	docker tag $(base_image) $(base_image)
	docker push $(base_image)

push-server:
	docker tag $(server_image) $(latest_server_image)
	docker tag $(server_image) $(server_image)-$(GIT_HASH)
	docker push $(server_image)-$(GIT_HASH)
	docker push $(latest_server_image)

push-server-release:
	docker tag $(server_image) $(server_image)
	docker push $(server_image)

push: push-base push-server

push-release: push-base-release push-server-release

.PHONY: base server push push-release push-base push-server push-base-release push-server-release
