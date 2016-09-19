#!/bin/bash
set -e
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

if [ "${DEBUG}" == true ]; then
  set -x
fi

NGINX_CONFIG_PATH=/build/config/nginx

apt-get update

# ONBUILD does this
#cp ${NGINX_CONFIG_PATH}/default.conf /etc/nginx/conf.d/default.conf

## Install CertBot
wget https://dl.eff.org/certbot-auto
mv certbot-auto /usr/local/sbin
chmod a+x /usr/local/sbin/certbot-auto
/usr/local/sbin/certbot-auto --non-interactive --os-packages-only
