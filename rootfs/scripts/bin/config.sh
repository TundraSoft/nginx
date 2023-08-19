#!/bin/sh

CONFIG_FILE="config.json"
CONFIG_DATA=$(cat ${CONFIG_FILE})

# Function to list domains
list_domains() {
  echo ${CONFIG_DATA} | jq -r 'keys[]'
}

# Function to list upstreams of a domain
list_upstreams() {
  local domain=$1
  echo ${CONFIG_DATA} | jq -r ".${domain}.upstreams | keys[]"
}

# Function to add an upstream to a domain
add_upstream() {
  local domain=$1
  local upstream=$2
  local port=$3
  local server=$4
  local weight=$5
  local fail_timeout=$6
  local max_fails=$7
  local backup=$8
  local down=$9
  
  CONFIG_DATA=$(echo ${CONFIG_DATA} | jq ".${domain}.upstreams.${upstream} = {\"port\": ${port}, \"servers\": {\"${server}\": {\"weight\": ${weight}, \"fail_timeout\": ${fail_timeout}, \"max_fails\": ${max_fails}, \"backup\": ${backup}, \"down\": ${down}}}}")
  echo ${CONFIG_DATA} > ${CONFIG_FILE}
}

# Function to remove an upstream from a domain
remove_upstream() {
  local domain=$1
  local upstream=$2
  
  CONFIG_DATA=$(echo ${CONFIG_DATA} | jq "del(.${domain}.upstreams.${upstream})")
  echo ${CONFIG_DATA} > ${CONFIG_FILE}
}

# Test the functions
echo "Listing domains:"
list_domains

echo "Listing upstreams for 'api.anq.finance':"
list_upstreams "api.anq.finance"

echo "Adding new upstream 'new_upstream' to 'api.anq.finance':"
add_upstream "api.anq.finance" "new_upstream" 1236 "2.2.2.2" 1 10 3 false false

echo "Listing upstreams for 'api.anq.finance' after adding 'new_upstream':"
list_upstreams "api.anq.finance"

echo "Removing 'new_upstream' from 'api.anq.finance':"
remove_upstream "api.anq.finance" "new_upstream"

echo "Listing upstreams for 'api.anq.finance' after removing 'new_upstream':"
list_upstreams "api.anq.finance"