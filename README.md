# docker-nginx-ssl

[![Build Status](https://travis-ci.com/madharjan/docker-nginx-ssl.svg?branch=master)](https://travis-ci.com/madharjan/docker-nginx-ssl)
[![Layers](https://images.microbadger.com/badges/image/madharjan/docker-nginx-ssl.svg)](http://microbadger.com/images/madharjan/docker-nginx-ssl)

Docker container for Nginx with Certbot SSL based on [madharjan/docker-nginx](https://github.com/madharjan/docker-nginx/)

## Features

* Environment variables to configure Certbot SSL
* Preconfigured to redirect to prefix (e.g www) for request without subdomain (e.g http://company.com to http://www.company.com)
* Preconfigured to redirect all HTTP to HTTPS 
* Bats [bats-core/bats-core](https://github.com/bats-core/bats-core) based test cases
* Deploy/update web projects from git
* Setup reverse proxy

## Nginx 1.10.3 & Certbot SSL (docker-nginx-ssl)

### Environment

| Variable             | Default | Example                                                          |
|----------------------|---------|------------------------------------------------------------------|
| DISABLE_NGINX        | 0       | 1 (to disable)                                                   |
| DISABLE_SSL          | 0       | 1 (to disable)                                                   |
|                      |         |                                                                  |
| SSL_DOMAIN           |         | mycompany.com                                                    |
| SSL_EMAIL            |         | me@email.com                                                     |
| SSL_PREFIX           | www     | mail                                                             |
| CERTBOT_STAGE        |         | true                                                             |
|                      |         |                                                                  |
| INSTALL_PROJECT      | 0       | 1 (to enable)                                                    |
| PROJECT_GIT_REPO     |         | https://github.com/BlackrockDigital/startbootstrap-creative.git  |
| PROJECT_GIT_TAG      |         | v5.1.4                                                           |
|                      |         |                                                                  |
| DEFAULT_PROXY        | 0       | 1 (to enable)                                                    |
| PROXY_SCHEME         | http    | https                                                            |
| PROXY_HOST           |         | 127.0.0.1                                                        |
| PROXY_PORT           | 8080    | 8000                                                             |

## Build

```bash
# clone project
git clone https://github.com/madharjan/docker-nginx-ssl
cd docker-nginx-ssl

# build
make

# tests
make run
make test

# clean
make clean
```

## Run

### Configure DNS server for domain

Replace `${DOMAIN}` with your domain. e.g `mycompany.com`
Replace `${IP-ADDRESS}` with your server IP Address

```txt
${DOMAIN}`. 1800 IN A ${IP-ADDRESS}`
www.${DOMAIN}`. 1800 IN CNAME ${DOMAIN}`.
```

**Note**: update environment variables below as necessary

```bash
# prepare foldor on host for container volumes
sudo mkdir -p /opt/docker/nginx/etc/conf.d
sudo mkdir -p /opt/docker/nginx/html/
sudo mkdir -p /opt/docker/nginx/log/
sudo mkdir -p /opt/docker/certbot/tmp

# stop & remove previous instances
docker stop nginx-ssl
docker rm nginx-ssl

# run container
docker run -d \
  -e SSL_DOMAIN=mycompany.com \
  -e SSL_EMAIL=me@email.com \
  -p 80:80 \
  -p 443:443 \
  -v /opt/docker/nginx/etc/conf.d:/etc/nginx/conf.d \
  -v /opt/docker/nginx/html:/var/www/html \
  -v /opt/docker/nginx/log:/var/log/nginx \
  -v /opt/docker/certbot:/etc/certbot \
  --name nginx-ssl \
  madharjan/docker-nginx-ssl:1.10.3
```

## Systemd Unit File

**Note**: update environment variables below as necessary

```txt
[Unit]
Description=Nginx

After=docker.service

[Service]
TimeoutStartSec=0

ExecStartPre=-/bin/mkdir -p /opt/docker/nginx/etc/conf.d
ExecStartPre=-/bin/mkdir -p /opt/docker/nginx/html
ExecStartPre=-/bin/mkdir -p /opt/docker/nginx/log
ExecStartPre=-/usr/bin/docker stop nginx
ExecStartPre=-/usr/bin/docker rm nginx
ExecStartPre=-/usr/bin/docker pull madharjan/docker-nginx:1.10.3

ExecStart=/usr/bin/docker run \
  -e SSL_DOMAIN=mycompany.com \
  -e SSL_EMAIL=me@email.com \
  -p 80:80 \
  -p 443:443 \
  -v /opt/docker/nginx/etc/conf.d:/etc/nginx/conf.d \
  -v /opt/docker/nginx/html:/var/www/html \
  -v /opt/docker/nginx/log:/var/log/nginx \
  -v /opt/docker/certbot:/etc/certbot \
  --name nginx-ssl \
  madharjan/docker-nginx-ssl:1.10.3

ExecStop=/usr/bin/docker stop -t 2 nginx

[Install]
WantedBy=multi-user.target
```

## Generate Systemd Unit File

| Variable             | Default          | Example                                                          |
|----------------------|------------------|------------------------------------------------------------------|
| PORT                 |                  | 80                                                               |
| VOLUME_HOME          | /opt/docker      | /opt/data                                                        |
| NAME                 | ngnix-ssl        |                                                                  |
|                      |                  |                                                                  |
| SSL_PORT             |                  | 443                                                              |
| SSL_DOMAIN           |                  | mycompany.com                                                    |
| SSL_EMAIL            |                  | me@email.com                                                     |
| SSL_PREFIX           | www              | mail                                                             |
|                      |                  |                                                                  |
| INSTALL_PROJECT      | 0                | 1 (to enable)  
| PROJECT_GIT_REPO     |                  | https://github.com/BlackrockDigital/startbootstrap-creative.git  |
| PROJECT_GIT_TAG      | HEAD             | v5.1.4                                                           |
|                      |                  |                                                                  |
| DEFAULT_PROXY        | 0                | 1 (to enable)                                                    |
| PROXY_SCHEME         | http             | https                                                            |
| PROXY_HOST           |                  | 127.0.0.1                                                        |
| PROXY_PORT           | 8080             | 8000                                                             |
|                      |                  |                                                                  |
| LINK_PROXY_CONTAINER |                  | nginx-web2py                                                     |

### With deploy web projects

```bash
# generate nginx.service
docker run --rm \
  -e PORT=80 \
  -e SSL_PORT=443 \
  -e SSL_DOMAIN=mycompany.com \
  -e SSL_EMAIL=me@email.com \
  -e INSTALL_PROJECT=1 \
  -e PROJECT_GIT_REPO=https://github.com/BlackrockDigital/startbootstrap-creative.git \
  -e PROJECT_GIT_TAG=v5.1.4 \
  madharjan/docker-nginx-ssl:1.10.3 \
  nginx-ssl-systemd-unit | \
  sudo tee /etc/systemd/system/nginx-ssl.service

sudo systemctl enable nginx-ssl
sudo systemctl start nginx-ssl
```

### With reverse proxy

```bash
# generate nginx.service
docker run --rm \
  -e PORT=80 \
  -e SSL_PORT=443 \
  -e SSL_DOMAIN=mycompany.com \
  -e SSL_EMAIL=me@email.com \
  -e DEFAULT_PROXY=1 \
  -e PROXY_HOST=odoo \
  -e PROXY_PORT=8080 \
  -e LINK_CONTAINERS=odoo:odoo,nginx:website \
  madharjan/docker-nginx:1.10.3 \
  nginx-systemd-unit | \
  sudo tee /etc/systemd/system/nginx-ssl.service

sudo systemctl enable nginx-ssl
sudo systemctl start nginx-ssl
```

## Add virtualhost reverse proxy config

| Variable             | Default          | Example                                                          |
|----------------------|------------------|------------------------------------------------------------------|
| PROXY_VHOST_NAME     |                  | myapp.local                                                      |
| PROXY_SCHEME         | http             | https                                                            |
| PROXY_HOST           |                  | 127.0.0.1                                                        |
| PROXY_PORT           | 8080             | 8000                                                             |
| SSL_EMAIL            |                  | me@email.com                                                     |

```bash
# add proxy.conf
docker exec -it \
  -e PROXY_VHOST_NAME=myapp.company.com \
  -e PROXY_HOST=172.18.0.5 \
  -e PROXY_PORT=8080 \
  -e SSL_MAIL=me@mail.com \
  nginx-ssl \
  nginx-ssl-vhost-proxy-conf
```
