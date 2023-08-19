#!/command/with-contenv sh
# Renew SSL
if [ -n "${ACME_EMAIL}" ]; then
  echo "[info] Updating Certificates"
  acme --renew-all
  # We now need to move the certs to actual location
  echo "[info] Done updating certificates"
fi
