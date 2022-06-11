#!/command/with-contenv sh
# Renew SSL
if [ -z "${ACME_SSL_CA}" -a -z "${ACME_ACCOUNT_EMAIL}" ]
then
  echo "Updating Certificates"
  /acme/acme.sh --renew-all
  echo "Done updating certificates"
fi