# docker-nginx-ssl

[![](https://images.microbadger.com/badges/image/madharjan/docker-nginx-ssl.svg)](http://microbadger.com/images/madharjan/docker-nginx-ssl "Get your own image badge on microbadger.com")

Docker container for Nginx with Certbot SSL based on [madharjan/docker-nginx](https://github.com/madharjan/docker-nginx/)

* Nginx 1.4.6 & Certbot SSL (docker-nginx-ssl)

**Environment**

| Variable       | Default | Example        |
|----------------|---------|----------------|
| DISABLE_NGINX  | 0       | 1 (to disable) |
| DISABLE_SSL    | 0       | 1 (to disable) |
| SSL_DOMAIN     |         | mycompany.com  |
| SSL_EMAIL      |         | me@email.com   |
| SSL_PREFIX     | www     |                |
| CERTBOT_STAGE  |         | true           |

## Build

**Clone this project**
```
git clone https://github.com/madharjan/docker-nginx-ssl
cd docker-nginx-ssl
```

**Build Containers**
```
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

# update Changelog.md
# release
make release
```

**Tag and Commit to Git**
```
git tag 1.4.6
git push origin 1.4.6
```

## Run Container

### Nginx with Cetbot SSL

**Configure DNS server for domain**
Replace `${DOMAIN}` with your domain. e.g `mycompany.com`
Replace `${IP-ADDRESS}` with your server IP Address
```
${DOMAIN}`. 1800 IN A ${IP-ADDRESS}`
www.${DOMAIN}`. 1800 IN CNAME ${DOMAIN}`.
```

**Prepare folder on host for container volumes**
```
sudo mkdir -p /opt/docker/nginx/etc/conf.d
sudo mkdir -p /opt/docker/nginx/html/
sudo mkdir -p /opt/docker/nginx/log/
sudo mkdir -p /opt/docker/certbot/
```

**Run `nginx`**
```
docker stop nginx
docker rm nginx

docker run -d \
  -e DOMAIN=mycompany.com \
  -e EMAIL=me@email.com \
  -p 80:80 \
  -p 443:443 \
  -v /opt/docker/nginx/etc:/etc/nginx/conf.d \
  -v /opt/docker/nginx/html:/usr/share/nginx/html \
  -v /opt/docker/nginx/log:/var/log/nginx \
  -v /opt/docker/certbot:/etc/certbot \
  --name nginx \
  madharjan/docker-nginx-ssl:1.4.6
```

**Systemd Unit File**
```
[Unit]
Description=Nginx

After=docker.service

[Service]
TimeoutStartSec=0

ExecStartPre=-/bin/mkdir -p /opt/docker/nginx/html
ExecStartPre=-/bin/mkdir -p /opt/docker/nginx/etc/conf.d
ExecStartPre=-/bin/mkdir -p /opt/docker/certbot/etc
ExecStartPre=-/usr/bin/docker stop nginx
ExecStartPre=-/usr/bin/docker rm nginx
ExecStartPre=-/usr/bin/docker pull madharjan/docker-nginx-ssl:1.4.6

ExecStart=/usr/bin/docker run \
  -e DOMAIN=mycompany.com \
  -e EMAIL=me@email.com \
  -p 80:80 \
  -p 443:443 \
  -v /opt/docker/nginx/html:/usr/share/nginx/html \
  -v /opt/docker/nginx/etc/conf.d:/etc/nginx/conf.d \
  -v /opt/docker/nginx/log:/var/log/nginx \
  -v /opt/docker/certbot/etc:/etc/certbot \
  --name nginx \
  madharjan/docker-nginx-ssl:1.4.6

ExecStop=/usr/bin/docker stop -t 2 nginx

[Install]
WantedBy=multi-user.target
```
