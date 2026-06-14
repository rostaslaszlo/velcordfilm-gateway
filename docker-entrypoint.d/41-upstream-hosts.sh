#!/bin/sh
# A nginx.conf docker-compose-hez van írva, ezért az upstream-ek hardcode-olt
# "frontend"/"offerservice" service-neveket használnak. Azure Container Apps
# környezetben ezek nem léteznek mint hostname - ott a Container App-ok belső
# FQDN-jét kell használni (FRONTEND_HOST / OFFERSERVICE_HOST env var).
#
# Ha a változók nincsenek beállítva (pl. docker-compose), a default
# "frontend"/"offerservice" marad, és ez a script nem ír át semmit.
set -e

FRONTEND_HOST="${FRONTEND_HOST:-frontend}"
OFFERSERVICE_HOST="${OFFERSERVICE_HOST:-offerservice}"

sed -i "s/server frontend:80;/server ${FRONTEND_HOST}:80;/" /etc/nginx/nginx.conf
sed -i "s/server offerservice:3000;/server ${OFFERSERVICE_HOST}:3000;/" /etc/nginx/nginx.conf

echo "[gateway] upstream hosts: frontend=${FRONTEND_HOST} offerservice=${OFFERSERVICE_HOST}"
