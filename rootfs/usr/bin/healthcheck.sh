#!/bin/sh

#/package/admin/s6/command/s6-svstat /run/s6-rc/servicedirs/nginx || exit 1

SERVICE=$(/package/admin/s6/command/s6-svstat /run/s6-rc/servicedirs/nginx)
if echo "$SERVICE" | grep -q "down"; then
  echo "$SERVICE"
  exit 1
else
  echo "$SERVICE"
fi