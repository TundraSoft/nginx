#!/bin/sh
if [ ! -z "${MAXMIND_VERSION}" ]
then
  echo "Checking for MAXMIND GEO IP update process"
  # MAXMIND_COUNTRY_URL="https://download.maxmind.com/app/geoip_download?edition_id=${MAXMIND_VERSION}-Country&license_key=${MAXMIND_KEY}&suffix=tar.gz"
  MAXMIND_URL="https://download.maxmind.com/app/geoip_download?edition_id=${MAXMIND_VERSION}&license_key=${MAXMIND_KEY}&suffix=tar.gz"
  BACKUP_DATE=$(date +%Y-%m-%d)

  # Refresh maxmind geo ip data
  if [ ! -z "${MAXMIND_KEY}" ]
  then
    # If key is present then we proceed
    echo "Downloading latest file"
    wget ${MAXMIND_URL} -O /tmp/${MAXMIND_VERSION}.tar.gz
    mkdir /tmp/maxmind

    # Unzip
    tar -xf /tmp/${MAXMIND_VERSION}.tar.gz -C /tmp/maxmind --strip-components 1
    echo "Checking if this is a new version"
    if [ ! -f "/etc/nginx/maxmind/${MAXMIND_VERSION}.mmdb" ]
    then
      cp /tmp/maxmind/${MAXMIND_VERSION}.mmdb /etc/nginx/maxmind/${MAXMIND_VERSION}.mmdb
    else
      # Check hash
      NEW_HASH=$(sha512sum "/tmp/maxmind/${MAXMIND_VERSION}.mmdb" | sed "s/ \/tmp\/maxmind\/${MAXMIND_VERSION}.mmdb$//")
      CURRENT_HASH=$(sha512sum "/etc/nginx/maxmind/${MAXMIND_VERSION}.mmdb" | sed "s/ \/etc\/nginx\/maxmind\/${MAXMIND_VERSION}.mmdb$//")
      if [ $CURRENT_HASH != $NEW_HASH ]
      then
        # Backup existing
        mv /etc/nginx/maxmind/${MAXMIND_VERSION}.mmdb /etc/nginx/maxmind/${MAXMIND_VERSION}-${BACKUP_DATE}.mmdb
        # Move to folder
        mv /tmp/maxmind/${MAXMIND_VERSION}.mmdb /etc/nginx/maxmind/${MAXMIND_VERSION}.mmdb
      fi
    fi
    echo "Cleaning up"
    # Cleanup
    rm -rf /tmp/maxmind
    rm -rf /tmp/${MAXMIND_VERSION}.tar.gz
  fi
  echo "Done checking for MAXMIND GEO IP update process"
fi