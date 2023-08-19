#!/bin/sh
compare_move() {
  NEW_FILE=$1
  OLD_FILE=$2
  BACKUP_DATE=$(date +%Y-%m-%d)
  if [ ! -f $OLD_FILE ]; then
    mv $NEW_FILE $OLD_FILE
  else
    NEW_HASH=$(sha512sum "${NEW_FILE}" | cut -d " " -f 1)
    # | sed "s/ \/tmp\/maxmind\/${MAXMIND_VERSION}.mmdb$//")
    OLD_HASH=$(sha512sum "${OLD_FILE}" | cut -d " " -f 1)
    if [ $NEW_HASH != $OLD_HASH ]; then
      mv $OLD_FILE $OLD_FILE.${BACKUP_DATE}
      mv $NEW_FILE $OLD_FILE
    fi
  fi
}

download_update() {
  LICENSE_KEY=$1
  MAXMIND_BASE_EDITION=$2
  for MAXMIND_FILE in 'Country' 'City'; do
    MAXMIND_DOWNLOAD_FILE="${MAXMIND_BASE_EDITION}-${MAXMIND_FILE}"
    MAXMIND_DOWNLOAD_URL="https://download.maxmind.com/app/geoip_download?edition_id=${MAXMIND_DOWNLOAD_FILE}&license_key=${MAXMIND_KEY}&suffix=tar.gz"
    echo "Fetching ${MAXMIND_DOWNLOAD_FILE}..."
    wget ${MAXMIND_DOWNLOAD_URL} -O /tmp/${MAXMIND_DOWNLOAD_FILE}.tar.gz
    tar -xf /tmp/${MAXMIND_DOWNLOAD_FILE}.tar.gz -C /tmp/maxmind --strip-components 1
    rm /tmp/${MAXMIND_DOWNLOAD_FILE}.tar.gz
    echo "Updating ${MAXMIND_FILE}..."
    compare_move /tmp/maxmind/${MAXMIND_DOWNLOAD_FILE}.mmdb "${MAXMIND_PATH}/maxmind-${MAXMIND_FILE}.mmdb"
    echo "Setting permission to ${MAXMIND_PATH}/maxmind-${MAXMIND_FILE}.mmdb"
    setgroup "${MAXMIND_PATH}/maxmind-${MAXMIND_FILE}.mmdb"
  done
}

if [ ! -z "${MAXMIND_KEY}" ]; then
  echo "MAXMIND Key found. Running update process"
  mkdir -p /tmp/maxmind
  # If another process has started, then skip
  if [ ! -f /tmp/maxmind/run ]; then
    touch /tmp/maxmind/run
    MAXMIND_EDITION=${MAXMIND_EDITION:-'GeoLite2'}
    echo "Fetching files for edition ${MAXMIND_EDITION}"
    download_update $MAXMIND_KEY $MAXMIND_EDITION
    rm -rf /tmp/maxmind/*
  fi
fi
