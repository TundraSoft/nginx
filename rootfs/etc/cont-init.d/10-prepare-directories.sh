#!/command/with-contenv sh
# NGINX_DIRECTORIES=(/var/log/nginx /webroot /webroot/.well-known/acme-challenge /etc/nginx/certificates /etc/nginx/sites.d /etc/nginx/templates /tmp/modsecurity/data /tmp/modsecurity/upload /tmp/modsecurity/tmp)

# Set nginx folder permission
chown -R ${UNAME}:${GNAME} /usr/local/nginx
# Create nginx.pid if missing
if [ ! -f "/var/run/nginx.pid" ]
then
  touch /var/run/nginx.pid
fi
# set pid permission
# chown -R ${UNAME}:${GNAME} /var/run/nginx.pid

for i in /var/log/nginx /${NGINX_WEBROOT} ${NGINX_WEBROOT}/defaults/acme-challenge ${NGINX_WEBROOT}/defaults/error ${NGINX_WEBROOT}/defaults/filelist /etc/nginx/certificates /etc/nginx /etc/nginx/sites.d /etc/nginx/templates /tmp/modsecurity/data /tmp/modsecurity/upload /tmp/modsecurity/tmp /var/log/nginx/modsecuriy
do
  if [ ! -d "${i}" ]
  then
    echo "Create directory ${i}"
    mkdir -p ${i}
  fi
done

# Create website directories
# TODO - Log path
echo ${SITES} | sed -n 1'p' | tr ',' '\n' | while read SITE; do
    mkdir -p "${NGINX_WEBROOT}/${SITE}"
done
echo ${SECURE_SITES} | sed -n 1'p' | tr ',' '\n' | while read SITE; do
    mkdir -p "${NGINX_WEBROOT}/${SITE}"
done

for i in /var/log/nginx ${NGINX_WEBROOT} /etc/nginx /tmp/modsecurity /var/run/nginx.pid /acme /scripts
do
  echo "Setting ownership for ${i}"
  if [ -d "${i}" ]
  then
    chown -R ${UNAME}:${GNAME} ${i}
  else
    chown ${UNAME}:${GNAME} ${i}
  fi
done
