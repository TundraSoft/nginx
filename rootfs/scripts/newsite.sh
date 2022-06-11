#!/bin/sh
# -d CSV of domains
# -www Website to use WWW
# -ssl
# -alias

while getopts d:www:ssl:alias: flag
do
  case "${flag}" in
    d) DOMAIN=${OPTARG};;
    www) WWW=${OPTARG};;
    ssl) SSL=${OPTARG};;
    alias) ALIAS_DOMAINS=${OPTARG};;
  esac
done

SITE_CONFIG=/etc/nginx/sites.d/${DOMAIN}.enabled.config
SITE_CONFIG_DISABLED=/etc/nginx/sites.d/${DOMAIN}.disabled.config
WEBROOT_PATH=${WEBROOT}/${DOMAIN}
LOG_PATH=/var/log/nginx/${DOMAIN}
# Ok, now we first check if domain is already present in our list
if [ -f SITE_CONFIG -o -f SITE_CONFIG_DISABLED ]
then
  echo "Disabled config found. We simply exit"
fi
# Create directories
if [ ! -d ${WEBROOT_PATH} ]
then
  mkdir -p ${WEBROOT_PATH}
fi
if [ ! -d ${LOG_PATH} ]
then
  mkdir -p ${LOG_PATH}
fi
# Change permissions
chown -R ${UNAME}:${GNAME} ${WEBROOT_PATH}

# Config
# Merge config to suit
CONFIG_SSL=
CONFIG_ALIAS_DOMAINS=
CONFIG_WWW=
CONFIG_FILE=

if [ ! -z ${ALIAS_DOMAINS} ]
then
  # For each alias, we append to server variable
  
fi
if [ ! -z ${SSL} ]
then
  # We need to setup SSL
  echo "Generate SSL"
fi
# Generate config

# Finito