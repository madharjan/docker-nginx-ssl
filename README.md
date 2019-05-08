# docker-nginx-ssl

[![Build Status](https://travis-ci.com/madharjan/docker-nginx-ssl.svg?branch=master)](https://travis-ci.com/madharjan/docker-nginx-ssl)
[![Layers](https://images.microbadger.com/badges/image/madharjan/docker-nginx-ssl.svg)](http://microbadger.com/images/madharjan/docker-nginx-ssl)

Docker container for Nginx with Certbot SSL based on [madharjan/docker-nginx](https://github.com/madharjan/docker-nginx/)

## Features

* Environment variables to configure Certbot SSL
* Preconfigured to redirect to prefix (e.g www) for request without subdomain (e.g http://company.com to http://www.company.com)
* Preconfigured to redirect all HTTP to HTTPS 
* Bats ([bats-core/bats-core](https://github.com/bats-core/bats-core)) based test cases
* Deploy/update web projects from git

## Nginx 1.10.3 & Certbot SSL (docker-nginx-ssl)

### Environment

| Variable            | Default | Example                                                          |
|---------------------|---------|------------------------------------------------------------------|
| DISABLE_NGINX       | 0       | 1 (to disable)                                                   |
| DISABLE_SSL         | 0       | 1 (to disable)                                                   |
| SSL_DOMAIN          |         | mycompany.com                                                    |
| SSL_EMAIL           |         | me@email.com                                                     |
| SSL_PREFIX          | www     | mail                                                             |
| CERTBOT_STAGE       |         | true                                                             |
| INSTALL_PROJECT     | 0       | 1 (to enable)                                                    |
| PROJECT_GIT_REPO    |         | https://github.com/BlackrockDigital/startbootstrap-creative.git  |
| PROJECT_GIT_TAG     |         | v1.0.1                                                           |

## Build

### Clone this project

```bash
git clone https://github.com/madharjan/docker-nginx-ssl
cd docker-nginx-ssl
```

### Build Container

```bash
# login to DockerHub
docker login

# build
make

# tests
make run
make tests
make clean

# tag
make tag_latest

# release
make release
```

### Tag and Commit to Git

```bash
git tag 1.10.3
git push origin 1.10.3
```

## Run Container

### Nginx with Cetbot SSL

**Configure DNS server for domain**

Replace `${DOMAIN}` with your domain. e.g `mycompany.com`

Replace `${IP-ADDRESS}` with your server IP Address

```txt
${DOMAIN}`. 1800 IN A ${IP-ADDRESS}`
www.${DOMAIN}`. 1800 IN CNAME ${DOMAIN}`.
```

### Prepare folder on host for container volumes

```bash
sudo mkdir -p /opt/docker/nginx/etc/conf.d
sudo mkdir -p /opt/docker/nginx/html/
sudo mkdir -p /opt/docker/nginx/log/
sudo mkdir -p /opt/docker/certbot/tmp
```

### Run `docker-nginx-ssl`

```bash
docker stop nginx-ssl
docker rm nginx-ssl

docker run -d \
  -e SSL_DOMAIN=mycompany.com \
  -e SSL_EMAIL=me@email.com \
  -p 80:80 \
  -p 443:443 \
  -v /opt/docker/nginx/etc:/etc/nginx/conf.d \
  -v /opt/docker/nginx/html:/var/www/html \
  -v /opt/docker/nginx/log:/var/log/nginx \
  -v /opt/docker/certbot:/etc/certbot \
  --name nginx-ssl \
  madharjan/docker-nginx-ssl:1.10.3
```

## Run via Systemd

### Systemd Unit File - basic example

```txt
[Unit]
Description=Nginx

After=docker.service

[Service]
TimeoutStartSec=0

ExecStartPre=-/bin/mkdir -p /opt/docker/nginx/etc/conf.d
ExecStartPre=-/bin/mkdir -p /opt/docker/nginx/html
ExecStartPre=-/bin/mkdir -p /opt/docker/nginx/log
ExecStartPre=-/bin/mkdir -p /opt/docker/certbot/tmp
ExecStartPre=-/usr/bin/docker stop nginx-ssl
ExecStartPre=-/usr/bin/docker rm nginx-ssl
ExecStartPre=-/usr/bin/docker pull madharjan/docker-nginx-ssl:1.10.3

ExecStart=/usr/bin/docker run \
  -e SSL_DOMAIN=mycompany.com \
  -e SSL_EMAIL=me@email.com \
  -p 80:80 \
  -p 443:443 \
  -v /opt/docker/nginx/html:/usr/share/nginx/html \
  -v /opt/docker/nginx/etc/conf.d:/etc/nginx/conf.d \
  -v /opt/docker/nginx/log:/var/log/nginx \
  -v /opt/docker/certbot:/etc/certbot \
  --name nginx-ssl \
  madharjan/docker-nginx-ssl:1.10.3

ExecStop=/usr/bin/docker stop -t 2 nginx

[Install]
WantedBy=multi-user.target
```

### Generate Systemd Unit File - with deploy web projects

| Variable            | Default          | Example                                                          |
|---------------------|------------------|------------------------------------------------------------------|
| PORT                | 80               | 8080                                                             |
| VOLUME_HOME         | /opt/docker      | /opt/data                                                        |
| VERSION             | 1.10.3           | latest                                                           |
| INSTALL_PROJECT     | 0                | 1 (to enable)                                                    |
| PROJECT_GIT_REPO    |                  | https://github.com/BlackrockDigital/startbootstrap-creative.git  |
| PROJECT_GIT_TAG     | HEAD             | v5.1.4                                                           |
| SSL_PORT            | 443              | 8443                                                             |
| SSL_DOMAIN          |                  | mycompany.com                                                    |
| SSL_EMAIL           |                  | me@email.com                                                     |
| SSL_PREFIX          | www              | mail                                                             |

```bash
docker run --rm -it \
  -e PORT=80 \
  -e VOLUME_HOME=/opt/docker \
  -e VERSION=1.10.3 \
  -e INSTALL_PROJECT=1 \
  -e PROJECT_GIT_REPO=https://github.com/BlackrockDigital/startbootstrap-creative.git \
  -e PROJECT_GIT_TAG=v5.1.4 \
  -e SSL_PORT=443 \
  -e SSL_DOMAIN=mycompany.com \
  -e SSL_EMAIL=me@email.com \
  -e SSL_PREFIX=www \
  madharjan/docker-nginx-ssl:1.10.3 \
  /bin/sh -c "nginx-ssl-systemd-unit" | \
  sudo tee /etc/systemd/system/nginx-ssl.service

sudo systemctl enable nginx-ssl
sudo systemctl start nginx-ssl
```
