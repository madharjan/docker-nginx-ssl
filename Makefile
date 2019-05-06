
NAME = madharjan/docker-nginx-ssl
VERSION = 1.10.3

DEBUG ?= true

.PHONY: all build build_test clean_images test tag_latest release

all: build

build:
	docker build \
	 --build-arg VCS_REF=`git rev-parse --short HEAD` \
	 --build-arg DEBUG=$(DEBUG) \
	 -t $(NAME):$(VERSION) --rm .

run:
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

tests:
	sleep 3
	./bats/bin/bats test/tests.bats

stop:
	docker exec nginx-ssl /bin/bash -c "rm -rf /etc/nginx/conf.d/*" || true
	docker exec nginx-ssl /bin/bash -c "rm -rf /var/www/html/*" || true
	docker exec nginx-ssl_project /bin/bash -c "rm -rf /etc/nginx/conf.d/*" || true
	docker exec nginx-ssl_project /bin/bash -c "rm -rf /var/www/html/*" || true
	docker exec nginx-ssl_project /bin/bash -c "rm -rf /var/www/html/.git" || true
	docker stop nginx-ssl nginx-ssl_no_ssl nginx-ssl_project || true

clean: stop
	docker rm nginx-ssl nginx-ssl_no_ssl nginx-ssl_project|| true
	rm -rf /tmp/nginx-ssl || true
	rm -rf /tmp/nginx-ssl_project || true

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest

release: run tests clean tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)
	@echo "*** Don't forget to create a tag. git tag $(VERSION) && git push origin $(VERSION) ***"
	curl -s -X POST https://hooks.microbadger.com/images/madharjan/docker-nginx-ssl/DU0MPYgUEFj9TVUGoJ_sWbZx6Kk=

clean_images:
	docker rmi $(NAME):latest $(NAME):$(VERSION) || true
