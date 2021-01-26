.SILENT:

PREPARE := $(shell test -e ../.env || cp ../.env.dist ../.env)
IS_ENV_PRESENT := $(shell test -e ../.env && echo -n yes)
GIT_HASH := $(shell git rev-parse --short HEAD)

ifeq ($(IS_ENV_PRESENT), yes)
	include ../.env
	export $(shell sed 's/=.*//' ../.env)
endif

server_version=${VERSION}

server_image=h44z/seafile-ce:$(server_version)
latest_server_image=h44z/seafile-ce:latest

all:
	@echo
	@echo Pleaes use '"make server"' or '"make push"'.
	@echo

server:
	@echo Building seafile server version ${VERSION}
	cd seafile && docker build --no-cache -t $(server_image) . --build-arg SEAFILE_VERSION=${VERSION} \
		--build-arg LDAP_IGNORE_CERT_CHECK=${LDAP_IGNORE_CERT_CHECK}

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
