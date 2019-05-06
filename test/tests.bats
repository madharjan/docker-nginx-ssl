@test "checking process: nginx (master process)" {
  run docker exec nginx-ssl /bin/bash -c "ps aux | grep -v grep | grep 'nginx: master process /usr/sbin/nginx'"
  [ "$status" -eq 0 ]
}

@test "checking process: nginx (worker process)" {
  run docker exec nginx-ssl /bin/bash -c "ps aux | grep -v grep | grep 'nginx: worker process'"
  [ "$status" -eq 0 ]
}

@test "checking process: nginx (master process disabled by DISABLE_NGINX)" {
  run docker exec nginx-ssl_no_nginx /bin/bash -c "ps aux | grep -v grep | grep 'nginx: master process /usr/sbin/nginx'"
  [ "$status" -eq 1 ]
}

@test "checking process: nginx (worker process disabled by DISABLE_NGINX)" {
  run docker exec nginx-ssl_no_nginx /bin/bash -c "ps aux | grep -v grep | grep 'nginx: worker process'"
  [ "$status" -eq 1 ]
}

@test "checking request: status (index.html via http)" {
  run docker exec nginx-ssl /bin/bash -c "curl -I -s http://mycompany.com/index.html | head -n 1 | cut -d$' ' -f2"
  [ "$status" -eq 0 ]
  [ "$output" -eq 301 ]
}

@test "checking request: content (index.html via http->https)" {
  run docker exec nginx-ssl /bin/bash -c "curl -k -s -L http://mail.mycompany.com/index.html | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 18 ]
}

@test "checking request: status (index.html via https)" {
  run docker exec nginx-ssl /bin/bash -c "curl -k -I -s -L https://mail.mycompany.com/index.html | head -n 1 | cut -d$' ' -f2"
  [ "$status" -eq 0 ]
  [ "$output" -eq 200 ]
}

@test "checking request: content (index.html via https)" {
  run docker exec nginx-ssl /bin/bash -c "curl -k -s -L https://mail.mycompany.com/index.html | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 18 ]
}

@test "checking request: status (50x.html via https)" {
  run docker exec nginx-ssl /bin/bash -c "curl -k -i -s -L https://localhost/.500test | head -n 1 | cut -d$' ' -f2"
  [ "$status" -eq 0 ]
  [ "$output" -eq 502 ]
}

@test "checking request: content (50x.html via https)" {
  run docker exec nginx-ssl /bin/bash -c "curl -k -s -L https://localhost/.500test | grep '<h1>An error occurred.</h1>'"
  [ "$status" -eq 0 ]
}

@test "checking request: status (405.html via https)" {
  run docker exec nginx-ssl /bin/bash -c "curl -k -i -s -L -X OPTIONS https://localhost/.500test | head -n 1 | cut -d$' ' -f2"
  [ "$status" -eq 0 ]
  [ "$output" -eq 405 ]
}

@test "checking request: content (405.html via https)" {
  run docker exec nginx-ssl /bin/bash -c "curl -k -i -s -L -X OPTIONS http://localhost/.500test | grep '<h1>Method not allowed</h1>'"
  [ "$status" -eq 0 ]
}

@test "checking request: status (403.html via https)" {
  run docker exec nginx-ssl /bin/bash -c "curl -k -i -s -L https://localhost/.403test | head -n 1 | cut -d$' ' -f2"
  [ "$status" -eq 0 ]
  [ "$output" -eq 403 ]
}

@test "checking request: content (403.html via https)" {
  run docker exec nginx-ssl /bin/bash -c "curl -k -i -s -L https://localhost/.403test | grep '<h1>Access Denied</h1>'"
  [ "$status" -eq 0 ]
}

@test "checking request: status (404.html via https)" {
  run docker exec nginx-ssl /bin/bash -c "curl -k -i -s -L https://localhost/.404test | head -n 1 | cut -d$' ' -f2"
  [ "$status" -eq 0 ]
  [ "$output" -eq 404 ]
}

@test "checking request: content (404.html via https)" {
  run docker exec nginx-ssl /bin/bash -c "curl -k -i -s -L https://localhost/.404test | grep '<h1>File not found</h1>'"
  [ "$status" -eq 0 ]
}

@test "checking request: project_intial (index.html via https)" {
  run docker exec nginx-ssl_project /bin/bash -c "curl -k -s -L https://localhost/index.html | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 272 ]
}

@test "checking request: project_updated (index.html via https)" {

  docker stop nginx-ssl_project || true
	docker rm nginx-ssl_project || true
  docker run -d \
		-e DEBUG=true \
		-e CERTBOT_STAGE=true \
		-e SSL_DOMAIN=mycompany.com \
		-e SSL_EMAIL=nobody@myemail.com \
		-e SSL_PREFIX=mail \
		-v /tmp/nginx-ssl_project/etc:/etc/nginx/conf.d \
		-v /tmp/nginx-ssl_project/html:/var/www/html \
		-v "`pwd`/test/certbot":/etc/certbot \
		-e INSTALL_PROJECT=1 \
		-e PROJECT_GIT_REPO=https://github.com/BlackrockDigital/startbootstrap-creative.git \
    -e PROJECT_GIT_TAG=v5.1.4 \
		--name nginx-ssl_project madharjan/docker-nginx-ssl:1.10.3 

  sleep 3

  run docker exec nginx-ssl_project /bin/bash -c "curl -k -s -L https://localhost/index.html | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 262 ]
}
