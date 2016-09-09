# docker-nginx-ssl
Docker container for Nginx with Certbot SSL based on [madharjan/docker-nginx](https://github.com/madharjan/docker-nginx/)

* Nginx 1.4.6 & Certbot SSL (docker-nginx-ssl)

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

# test
make test

# tag
make tag_latest

# update Makefile & Changelog.md
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

**Run `nginx` container**
```
docker run -d -t \
  --name nginx \
  madharjan/docker-nginx-ssl:1.4.6 /sbin/my_init
```

**Prepare folder on host for container volumes**
```
sudo mkdir -p /opt/docker/nginx/etc/conf.d
sudo mkdir -p /opt/docker/nginx/html/
sudo mkdir -p /opt/docker/nginx/log/
sudo mkdir -p /opt/docker/certbot/tmp/
```

**Copy default configuration and html files to host**
```
sudo docker exec nginx tar Ccf /etc/nginx - conf.d | tar Cxf /opt/docker/nginx/etc -
sudo docker exec nginx tar Ccf /usr/share/nginx - html | tar Cxf /opt/docker/nginx -
```

**Update Nginx configuration as necessary**
```
sudo vi /opt/docker/nginx/etc/default.conf
```
**Update Webpage as necessary**
```
sudo vi /opt/docker/nginx/html/index.html
```

**Run `nginx` with updated configuration**
```
docker stop nginx
docker rm nginx

docker run -d -t \
  -p 80:80 \
  -p 443:443 \
  -v /opt/docker/nginx/etc:/etc/nginx/conf.d \
  -v /opt/docker/nginx/html:/usr/share/nginx/html \
  -v /opt/docker/nginx/log:/var/log/nginx \
  -v /opt/docker/certbot:/etc/certbot \
  --name nginx \
  madharjan/docker-nginx-ssl:1.4.6 /sbin/my_init
```

**Configure DNS server for domain**
Replace `${DOMAIN}` with your domain. e.g `mycompany.com`
Replace `${IP-ADDRESS}` with your server IP Address
```
${DOMAIN}`. 1800 IN A ${IP-ADDRESS}`
www.${DOMAIN}`. 1800 IN CNAME ${DOMAIN}`.
```

**Run Certbot to create SSL certificate for `www.${DOMAIN}`**
Replace ${EMAIL} with email address
Replace ${DOMAIN} with domain
```
docker exec -t \
   nginx \
   /usr/local/sbin/certbot-auto certonly -t -n --no-self-upgrade --agree-tos --webroot --config-dir /etc/certbot -m ${EMAIL} -w /etc/certbot/tmp -d www.${DOMAIN}

docker exec -t \
  nginx \
  /usr/bin/openssl dhparam -out /etc/certbot/dhparam.pem 2048
```

**Update Nginx configuration for SSL**
`vi /opt/docker/nginx/etc/default.conf`
```

...

# HTTP Site (prefix `www` if none exists)
server {
    server_name  ${DOMAIN};
    rewrite ^(.*) $scheme://www.${DOMAIN}$1 permanent;
}

# SSL Site
server {
    listen       443 ssl;
    server_name  www.${DOMAIN};

...

    ssl_certificate /etc/certbot/live/www.${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/certbot/live/www.${DOMAIN}/privkey.pem;
    ssl_dhparam /etc/certbot/dhparam.pem;

...

}
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
ExecStartPre=-/bin/mkdir -p /opt/docker/certbot/etc/tmp
ExecStartPre=-/usr/bin/docker stop nginx
ExecStartPre=-/usr/bin/docker rm nginx
ExecStartPre=-/usr/bin/docker pull madharjan/docker-nginx-ssl:1.4.6

ExecStart=/usr/bin/docker run \
  -p 80:80 \
  -p 443:443 \
  -v /opt/docker/nginx/html:/usr/share/nginx/html \
  -v /opt/docker/nginx/etc/conf.d:/etc/nginx/conf.d \
  -v /opt/docker/nginx/log:/var/log/nginx \
  -v /opt/docker/certbot/etc:/etc/certbot \
  --name nginx \
  madharjan/docker-nginx-ssl:1.4.6 /sbin/my_init

ExecStop=/usr/bin/docker stop -t 2 nginx

[Install]
WantedBy=multi-user.target
```
