server_version=7.0.5

base_image=h44z/base-mc:18.04
base_image_squashed=h44z/base-mc:18.04-squashed
server_image=h44z/seafile-mc:$(server_version)
server_image_squashed=h44z/seafile-mc:$(server_version)-squashed
latest_server_image=h44z/seafile-mc:latest

all:
	@echo
	@echo Pleaes use '"make base"' or '"make server"' or '"make push"'.
	@echo

base:
	docker pull phusion/baseimage:0.11
	docker-squash --tag phusion/baseimage:latest phusion/baseimage:0.11
	docker tag phusion/baseimage:latest phusion/baseimage:0.11
	cd base && docker build -t $(base_image) .
	docker-squash --tag $(base_image_squashed) $(base_image)
	docker tag $(base_image_squashed) $(base_image)
	docker rmi `docker images --filter "dangling=true" -q --no-trunc`

server:
	cd seafile && cp -rf ../../scripts ./ && docker build -t $(server_image) .
	docker-squash --tag $(server_image_squashed) $(server_image) --from-layer=$(base_image)
	docker tag $(server_image_squashed) $(server_image)
	docker tag $(server_image) $(latest_server_image)
	docker rmi `docker images --filter "dangling=true" -q --no-trunc`

push-base:
	docker push $(base_image)

push: push-base push-server

.PHONY: base server push push-base push-server
