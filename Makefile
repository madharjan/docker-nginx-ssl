
NAME = madharjan/docker-nginx-ssl
VERSION = 1.4.6

.PHONY: all build build_test clean_images test tag_latest release

all: build

build:
	docker build \
	 --build-arg VCS_REF=`git rev-parse --short HEAD` \
	 --build-arg DEBUG=true \
	 -t $(NAME):$(VERSION) --rm .

run:
	mkdir -p ./test/etc
	mkdir -p ./test/html

	docker run -d -t \
		-e DEBUG=true \
		-e CERTBOT_STAGE=true \
		-e SSL_DOMAIN=mycompany.com \
		-e SSL_EMAIL=nobody@myemail.com \
		-e SSL_PREFIX=mail \
	  -v "`pwd`/test/etc":/etc/nginx/conf.d \
		-v "`pwd`/test/html":/usr/share/nginx/html \
		-v "`pwd`/test/certbot":/etc/certbot \
		--name nginx -t $(NAME):$(VERSION)

	docker exec nginx /bin/bash -c "echo '127.0.0.1 mycompany.com' >> /etc/hosts"
	docker exec nginx /bin/bash -c "echo '127.0.0.1 mail.mycompany.com' >> /etc/hosts"

	docker run -d -t \
		-e DEBUG=true \
		-e DISABLE_SSL=1 \
		--name nginx_no_ssl -t $(NAME):$(VERSION)

tests:
	./bats/bin/bats test/tests.bats

clean:
	docker stop nginx nginx_no_ssl || true
	docker rm nginx nginx_no_ssl || true

	rm -rf ./test/etc
	rm -rf ./test/html

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest

release: test tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! head -n 1 Changelog.md | grep -q 'release date'; then echo 'Please note the release date in Changelog.md.' && false; fi
	docker push $(NAME)
	@echo "*** Don't forget to create a tag. git tag $(VERSION) && git push origin $(VERSION) ***"
	curl -X POST https://hooks.microbadger.com/images/madharjan/docker-nginx-ssl/DU0MPYgUEFj9TVUGoJ_sWbZx6Kk=

clean_images:
	docker rmi $(NAME):latest $(NAME):$(VERSION) || true
