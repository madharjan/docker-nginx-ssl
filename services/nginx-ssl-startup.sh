#!/bin/bash

set -e

if [ "${DEBUG}" == true ]; then
  set -x
fi

DISABLE_SSL=${DISABLE_SSL:-0}

SSL_DOMAIN=${SSL_DOMAIN:-}
SSL_EMAIL=${SSL_EMAIL:-}
SSL_PREFIX=${SSL_PREFIX:-www}
CERTBOT_STAGE=${CERTBOT_STAGE:-}
CERTBOT_ENV=

if [ "${CERTBOT_STAGE}" == true ]; then
  CERTBOT_ENV="--staging"
fi

if [ ! "${DISABLE_SSL}" -eq 0 ]; then
  # nginx-startup.sh runs after nginx-ssl-startup.sh - just delete
  rm -f /etc/nginx/conf.d/default-ssl.conf
  rm -f /etc/nginx/conf.d/default.conf
else
  if [ ! -f /etc/certbot/live/${SSL_PREFIX}.${SSL_DOMAIN}/privkey.pem ]; then
    /usr/local/sbin/certbot-auto certonly -t -n \
      --no-self-upgrade \
      --agree-tos \
      --standalone \
      --config-dir /etc/certbot \
      ${CERTBOT_ENV} \
      -m ${SSL_EMAIL} -d ${SSL_PREFIX}.${SSL_DOMAIN}
  fi

  if [ ! -f /etc/certbot/dhparam.pem ]; then
    /usr/bin/openssl dhparam -out /etc/certbot/dhparam.pem 2048
  fi

  cp /config/etc/nginx-ssl/conf.d/default.conf /etc/nginx/conf.d/default.conf
  cp /config/etc/nginx-ssl/conf.d/default-ssl.conf /etc/nginx/conf.d/default-ssl.conf
  export SSL_DOMAIN SSL_EMAIL SSL_PREFIX
  perl -p -i -e 's/\$\{([^}]+)\}/defined $ENV{$1} ? $ENV{$1} : $&/eg' /etc/nginx/conf.d/default-ssl.conf
fi
