
NAME = madharjan/docker-nginx-ssl
VERSION = 1.10.3

DEBUG ?= true

DOCKER_USERNAME ?= $(shell read -p "DockerHub Username: " pwd; echo $$pwd)
DOCKER_PASSWORD ?= $(shell stty -echo; read -p "DockerHub Password: " pwd; stty echo; echo $$pwd)
DOCKER_LOGIN ?= $(shell cat ~/.docker/config.json | grep "docker.io" | wc -l)

.PHONY: all build run test stop clean tag_latest release clean_images

all: build

docker_login:
ifeq ($(DOCKER_LOGIN), 1)
		@echo "Already login to DockerHub"
else
		@docker login -u $(DOCKER_USERNAME) -p $(DOCKER_PASSWORD)
endif

build:
	docker build \
	 --build-arg VCS_REF=`git rev-parse --short HEAD` \
	 --build-arg DEBUG=$(DEBUG) \
	 -t $(NAME):$(VERSION) --rm .

run:
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi

	rm -rf /tmp/nginx-ssl
	mkdir -p /tmp/nginx-ssl/etc
	mkdir -p /tmp/nginx-ssl/html

	docker run -d \
		-e DEBUG=$(DEBUG) \
		-e CERTBOT_STAGE=true \
		-e SSL_DOMAIN=mycompany.com \
		-e SSL_EMAIL=nobody@myemail.com \
		-e SSL_PREFIX=mail \
		-v /tmp/nginx-ssl/etc:/etc/nginx/conf.d \
		-v /tmp/nginx-ssl/html:/var/www/html \
		-v "`pwd`/test/certbot":/etc/certbot \
		--name nginx-ssl $(NAME):$(VERSION)

	sleep 3

	docker exec nginx-ssl /bin/bash -c "echo '127.0.0.1 mycompany.com' >> /etc/hosts"
	docker exec nginx-ssl /bin/bash -c "echo '127.0.0.1 mail.mycompany.com' >> /etc/hosts"

	docker run -d \
		-e DEBUG=$(DEBUG) \
		-e DISABLE_SSL=1 \
		--name nginx-ssl_no_ssl $(NAME):$(VERSION)

	sleep 2

	rm -rf /tmp/nginx-ssl_project
	mkdir -p /tmp/nginx-ssl_project/etc
	mkdir -p /tmp/nginx-ssl_project/html

	docker run -d \
		-e DEBUG=$(DEBUG) \
		-e CERTBOT_STAGE=true \
		-e SSL_DOMAIN=mycompany.com \
		-e SSL_EMAIL=nobody@myemail.com \
		-e SSL_PREFIX=mail \
		-v /tmp/nginx-ssl_project/etc:/etc/nginx/conf.d \
		-v /tmp/nginx-ssl_project/html:/var/www/html \
		-v "`pwd`/test/certbot":/etc/certbot \
		-e INSTALL_PROJECT=1 \
		-e PROJECT_GIT_REPO=https://github.com/BlackrockDigital/startbootstrap-creative.git \
		-e PROJECT_GIT_TAG=v5.0.0 \
		--name nginx-ssl_project $(NAME):$(VERSION) 

	sleep 4

	docker exec nginx-ssl_project /bin/bash -c "echo '127.0.0.1 mycompany.com' >> /etc/hosts"
	docker exec nginx-ssl_project /bin/bash -c "echo '127.0.0.1 mail.mycompany.com' >> /etc/hosts"

	docker run -d \
		--link nginx-ssl_project:project \
		-e DEBUG=$(DEBUG) \
		-e CERTBOT_STAGE=true \
		-e SSL_DOMAIN=mycompany.com \
		-e SSL_EMAIL=nobody@myemail.com \
		-e SSL_PREFIX=mail \
		-e DEFAULT_PROXY=1 \
		-e PROXY_HOST=project \
		-e PROXY_PORT=443 \
		-e PROXY_SCHEME=https \
		-v "`pwd`/test/certbot":/etc/certbot \
		--name nginx-ssl_proxy $(NAME):$(VERSION)

	sleep 2

	docker exec nginx-ssl_proxy /bin/bash -c "echo '127.0.0.1 mycompany.com' >> /etc/hosts"
	docker exec nginx-ssl_proxy /bin/bash -c "echo '127.0.0.1 mail.mycompany.com' >> /etc/hosts"

test:
	sleep 3
	./bats/bin/bats test/tests.bats

stop:
	docker exec nginx-ssl /bin/bash -c "rm -rf /etc/nginx/conf.d/*" 2> /dev/null || true
	docker exec nginx-ssl /bin/bash -c "rm -rf /var/www/html/*" 2> /dev/null || true
	docker exec nginx-ssl_project /bin/bash -c "rm -rf /etc/nginx/conf.d/*" 2> /dev/null || true
	docker exec nginx-ssl_project /bin/bash -c "rm -rf /var/www/html/*" 2> /dev/null || true
	docker exec nginx-ssl_project /bin/bash -c "rm -rf /var/www/html/.git" 2> /dev/null || true
	docker stop nginx-ssl nginx-ssl_no_ssl nginx-ssl_project nginx-ssl_proxy 2> /dev/null || true

clean: stop
	docker rm nginx-ssl nginx-ssl_no_ssl nginx-ssl_project nginx-ssl_proxy 2> /dev/null || true
	rm -rf /tmp/nginx-ssl || true
	rm -rf /tmp/nginx-ssl_project || true
	docker images | grep "<none>" | awk '{print$3 }' | xargs docker rmi 2> /dev/null || true

publish: docker_login run test clean
	docker push $(NAME)

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest

release: docker_login  run test clean tag_latest
	docker push $(NAME)

clean_images: clean
	docker rmi $(NAME):latest $(NAME):$(VERSION) 2> /dev/null || true
	docker logout 


