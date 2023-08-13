#!/bin/sh
CONFIG_HASH=$(nginx -T | sha512sum | sed "s/ *\-$//")
HASH_FILE=/tmp/nginx.hash
echo "Starting NGINX config auto-reload"
# Check if the hash file exists
if [ -f "${HASH_FILE}" ]
then
  # Load the value
  source ${HASH_FILE}
  # Check if the values match
  if [ ${NGINX_HASH} != ${CONFIG_HASH} ]
  then
    # No, they dont
    echo "NGINX config has changed... Need to reload"
    # Test the config file
    nginx -t
    # Did it pass the test?
    if [ $? -eq 0 ]
    then
      # Yes, lets reload
      echo "NGINX config found to be valid!"
      echo "Reloading NGINX config..."
      nginx -s reload
      # Remove old file
      echo "Removing old hash..."
      rm -f ${HASH_FILE}
    else
      # Config file did not pass! This can either be because of WIP changes or admin done f****d up. 
      # Lets ignore and give admin a break
      echo "NGINX config was not valid. Ignoring changes..."
    fi
  else
    echo "No change in config"
  fi
fi

# Check if file does not exist, and if it does not then create it
if [ ! -f "${HASH_FILE}" ]
then
  touch "${HASH_FILE}"
  echo "NGINX_HASH=${CONFIG_HASH}" >> "${HASH_FILE}"
fi

echo "Finished with NGINX config auto-reload"