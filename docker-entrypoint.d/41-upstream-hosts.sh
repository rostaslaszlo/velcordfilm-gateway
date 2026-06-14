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

# Azure Container Apps belso FQDN-ek mindig a 80/443 (ingress) porton hallgatnak,
# nem a konténer target_port-ján (offerservice eseten 3000) - ezert ha
# OFFERSERVICE_HOST be van allitva (Azure), a portot is 80-ra kell irni.
OFFERSERVICE_PORT=3000
if [ "$OFFERSERVICE_HOST" != "offerservice" ]; then
    OFFERSERVICE_PORT=80
fi

sed -i "s/server frontend:80;/server ${FRONTEND_HOST}:80;/" /etc/nginx/nginx.conf
sed -i "s/server offerservice:3000;/server ${OFFERSERVICE_HOST}:${OFFERSERVICE_PORT};/" /etc/nginx/nginx.conf
sed -i "s/proxy_set_header Host frontend;/proxy_set_header Host ${FRONTEND_HOST};/g" /etc/nginx/nginx.conf
sed -i "s/proxy_set_header Host offerservice;/proxy_set_header Host ${OFFERSERVICE_HOST};/g" /etc/nginx/nginx.conf

echo "[gateway] upstream hosts: frontend=${FRONTEND_HOST} offerservice=${OFFERSERVICE_HOST}:${OFFERSERVICE_PORT}"
