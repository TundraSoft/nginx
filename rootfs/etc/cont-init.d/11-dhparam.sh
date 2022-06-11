#!/command/with-contenv sh
# Generate dhparam file if missing
if [ ! -f "/etc/nginx/dhparam.pem" ]
then
  exec s6-setuidgid ${UNAME} openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 4096;
fi