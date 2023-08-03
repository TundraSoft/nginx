#!/command/with-contenv sh
# Renew SSL
if [ -n "${ACME_EMAIL}" ]
then
  echo "[info] Updating Certificates"
  acme --renew-all
  echo "[info] Done updating certificates"
fi