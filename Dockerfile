FROM madharjan/docker-nginx:1.4.6
MAINTAINER Madhav Raj Maharjan <madhav.maharjan@gmail.com>

LABEL description="Docker container for Nginx with SSL" os_version="Ubuntu 14.04"

ENV HOME /root

RUN mkdir -p /build
COPY . /build

RUN /build/scripts/install.sh && /build/scripts/cleanup.sh

VOLUME "/etc/nginx/conf.d", "/usr/share/nginx/html", "/var/log/nginx", "/etc/certbot"]

CMD ["/sbin/my_init"]

EXPOSE 80 443
