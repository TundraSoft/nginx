#!/command/with-contenv sh
if [ -z "${ACME_SSL_CA}" -a -z "${ACME_ACCOUNT_EMAIL}" ]
then
  exec s6-setuidgid ${UNAME} /acme/acme.sh --set-default-ca --server ${ACME_SSL_CA}
  # Move template
  /usr/local/bin/envsubst < "/templates/acme/account.template.conf" > "/acme/config/account.conf"
  /acme/acme.sh --register-account --server ${ACME_SSL_CA} -m ${ACME_ACCOUNT_EMAIL}
else
  if [ -f "/acme/config/account.conf" ]
  then
    rm -f "/acme/config/account.conf"
  fi
fi