#!/command/with-contenv sh
exec s6-setuidgid ${UNAME} /scripts/maxmind_refresh.sh
# Setup cron job