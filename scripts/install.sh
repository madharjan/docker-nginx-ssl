#!/bin/bash
set -e
source /build/config/buildconfig
set -x

NGINX_CONFIG_PATH=/build/config/nginx

apt-get update

# ONBUILD does this
#cp ${NGINX_CONFIG_PATH}/default.conf /etc/nginx/conf.d/default.conf

## Install CertBot
wget https://dl.eff.org/certbot-auto
mv certbot-auto /usr/local/sbin
chmod a+x /usr/local/sbin/certbot-auto
/usr/local/sbin/certbot-auto --non-interactive --os-packages-only
