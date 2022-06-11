#!/command/with-contenv sh
if [ ! -z ${SECURE_SITES} ]
then
  echo ${SECURE_SITES} | sed -n 1'p' | tr ',' '\n' | while read SITE; do
    if [ ! -f "/etc/nginx/sites.d/${SITE}.enabled.conf" ]
    then
      echo "Creating ${SITE} config..."
      export DOMAIN_NAME=${SITE}
      /usr/local/bin/envsubst < "/templates/nginx/https_basic.template.conf" > "/etc/nginx/sites.d/${SITE}.enabled.conf"
      # Get the SSL if it does not exist
      if [ ! -d "${SSL_PATH}/${SITE}"]
      then
        mkdir -p "${SSL_PATH}/${SITE}"
        /acme/acme.sh --issue -d ${SITE} -w ${NGINX_WEBROOT}/defaults/acme-challenge
      fi
    fi
  done
fi
if [ ! -z ${SITES} ]
then
  echo ${SITES} | sed -n 1'p' | tr ',' '\n' | while read SITE; do
    if [ ! -f "/etc/nginx/sites.d/${SITE}.enabled.conf" ]
    then
      echo "Creating ${SITE} config..."
      export DOMAIN_NAME=${SITE}
      /usr/local/bin/envsubst '$DOMAIN_NAME $NGINX_WEBROOT' < "/templates/nginx/http_basic.template.conf" > "/etc/nginx/sites.d/${SITE}.enabled.conf"
    fi
  done
fi
# Setup cron job