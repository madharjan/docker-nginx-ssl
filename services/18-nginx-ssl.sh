#!/bin/bash

set -e

if [ "${DEBUG}" = true ]; then
  set -x
fi

DISABLE_SSL=${DISABLE_SSL:-0}
DEFAULT_PROXY=${DEFAULT_PROXY:-0}
PROXY_HOST=${PROXY_HOST:-}
PROXY_PORT=${PROXY_PORT:-8080}
PROXY_SCHEME=${PROXY_SCHEME:-http}

SSL_DOMAIN=${SSL_DOMAIN:-}
SSL_EMAIL=${SSL_EMAIL:-}
SSL_PREFIX=${SSL_PREFIX:-www}
CERTBOT_STAGE=${CERTBOT_STAGE:-}
CERTBOT_ENV=

if [ "${CERTBOT_STAGE}" == true ]; then
  CERTBOT_ENV="--staging"
fi

if [ ! "${DISABLE_SSL}" -eq 0 ]; then
  # 20-nginx.sh runs after 15-nginx-ssl.sh - just delete
  rm -f /etc/nginx/conf.d/default-ssl.conf
  rm -f /etc/nginx/conf.d/default.conf
else
  if [ -f /etc/certbot/live/${SSL_PREFIX}.${SSL_DOMAIN}/privkey.pem ]; then
    echo "${SSL_PREFIX}.${SSL_DOMAIN}/privkey.pem already exists"
  else
    /usr/local/sbin/certbot-auto certonly -n \
      --no-self-upgrade \
      --agree-tos \
      --standalone \
      --config-dir /etc/certbot \
      --logs-dir /var/log/certbot \
      ${CERTBOT_ENV} \
      -m ${SSL_EMAIL} -d ${SSL_PREFIX}.${SSL_DOMAIN}
  fi

  if [ -f /etc/certbot/dhparam.pem ]; then
    echo "dhparam.pem already exists"
  else
    /usr/bin/openssl dhparam -out /etc/certbot/dhparam.pem 2048
  fi

  if [ -f /etc/nginx/conf.d/default.conf ]; then
    echo "Nginx config already exists"
  else 
    cp /config/etc/nginx-ssl/conf.d/default.conf /etc/nginx/conf.d/default.conf
  fi

  if [ -f /etc/nginx/conf.d/default-ssl.conf ]; then
    echo "Nginx SSL config already exists"
  else
    if [ ! "${DEFAULT_PROXY}" -eq 0 ]; then
      if [ -n "${PROXY_HOST}" ]; then
        cp /config/etc/nginx-ssl/conf.d/proxy-ssl.conf /etc/nginx/conf.d/default-ssl.conf
        sed -i "s/##PROXY_HOST##/${PROXY_HOST}/" /etc/nginx/conf.d/default-ssl.conf
        sed -i "s/##PROXY_PORT##/${PROXY_PORT}/" /etc/nginx/conf.d/default-ssl.conf
        sed -i "s/##PROXY_SCHEME##/${PROXY_SCHEME}/" /etc/nginx/conf.d/default-ssl.conf
      fi
    else 
      cp /config/etc/nginx-ssl/conf.d/default-ssl.conf /etc/nginx/conf.d/default-ssl.conf
    fi
    
    export SSL_DOMAIN SSL_EMAIL SSL_PREFIX
    perl -p -i -e 's/\$\{([^}]+)\}/defined $ENV{$1} ? $ENV{$1} : $&/eg' /etc/nginx/conf.d/default-ssl.conf
  fi

  if [ -f /etc/certbot/renewal/${SSL_PREFIX}.${SSL_DOMAIN}.conf ]; then
    cp /etc/certbot/renewal/${SSL_PREFIX}.${SSL_DOMAIN}.conf  /etc/certbot/renewal/${SSL_PREFIX}.${SSL_DOMAIN}.conf.orig
    sed -e "s/authenticator = .*/authenticator = webroot/g" -i /etc/certbot/renewal/${SSL_PREFIX}.${SSL_DOMAIN}.conf
    if grep -Fxq webroot_path /etc/certbot/renewal/${SSL_PREFIX}.${SSL_DOMAIN}.conf ; then
      echo "webroot_path = /etc/certbot/tmp" >> /etc/certbot/renewal/${SSL_PREFIX}.${SSL_DOMAIN}.conf
    fi
    if grep -Fxq webroot_map /etc/certbot/renewal/${SSL_PREFIX}.${SSL_DOMAIN}.conf ; then
      echo "[[webroot_map]]" >> /etc/certbot/renewal/${SSL_PREFIX}.${SSL_DOMAIN}.conf
      echo "${SSL_PREFIX}.${SSL_DOMAIN} = /etc/certbot/tmp" >> /etc/certbot/renewal/${SSL_PREFIX}.${SSL_DOMAIN}.conf
    fi
  fi


cat <<EOF > /etc/cron.daily/cerbot
#!/bin/sh

/usr/local/sbin/certbot-auto -n \
  --no-self-upgrade \
  --agree-tos \
  --config-dir /etc/certbot \
  --logs-dir /var/log/certbot \
  renew
EOF

fi
