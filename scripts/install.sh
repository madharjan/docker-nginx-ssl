#!/bin/bash
set -e
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

if [ "${DEBUG}" == true ]; then
  set -x
fi

NGINX_CONFIG_PATH=/build/config/nginx-ssl

#apt-get update

mkdir -p /config/etc/nginx-ssl/conf.d

cp ${NGINX_CONFIG_PATH}/default.conf /config/etc/nginx-ssl/conf.d/default.conf
cp ${NGINX_CONFIG_PATH}/default-ssl.conf /config/etc/nginx-ssl/conf.d/default-ssl.conf

## Install CertBot
wget https://dl.eff.org/certbot-auto
mv certbot-auto /usr/local/sbin
chmod a+x /usr/local/sbin/certbot-auto
/usr/local/sbin/certbot-auto --non-interactive --os-packages-only

mkdir -p /etc/my_init.d
cp /build/services/nginx-ssl-startup.sh /etc/my_init.d
chmod 750 /etc/my_init.d/nginx-ssl-startup.sh
