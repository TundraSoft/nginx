#!/bin/sh
#/package/admin/s6/command/s6-svstat /run/s6-rc/servicedirs/nginx || exit 1
SERVICE=$(/package/admin/s6/command/s6-svstat /run/s6-rc/servicedirs/nginx)
echo "$SERVICE"
if echo "$SERVICE" | grep -q "down"; then
  exit 1
elif ! curl -sk -A healthcheck "http://127.0.0.1/ping" | grep -q "pong"; then
  exit 1
fi