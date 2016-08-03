#!/bin/bash
set -e
source /build/config/buildconfig
set -x

NGINX_CONFIG_PATH=/build/config

apt-get update
apt-get upgrade -y --no-install-recommends

cp ${NGINX_CONFIG_PATH}/nginx-default.conf /etc/nginx/conf.d/default.conf

## Install CertBot
wget https://dl.eff.org/certbot-auto
cp certbot-auto /usr/local/sbin
chmod a+x /usr/local/sbin/certbot-auto
/usr/local/sbin/certbot-auto --non-interactive --os-packages-only
