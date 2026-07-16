#!/bin/sh
# TLS_DOMAIN unset/empty (default) -> no-op. This is the case on Azure
# Container Apps, where the platform terminates TLS itself and this gateway
# image never needs to.
#
# TLS_DOMAIN set -> the ACME HTTP-01 challenge location is always enabled
# (needed for both the first issuance and renewals). The HTTPS (443) server
# block + HTTP->HTTPS redirect are only added once a real certificate already
# exists at /etc/letsencrypt/live/$TLS_DOMAIN/ - on first boot, before certbot
# has obtained one yet, this script runs again after the certbot bootstrap
# step (see ../../velcordfilm-infra deploy scripts) restarts this container.
set -e

if [ -z "${TLS_DOMAIN:-}" ]; then
    echo "[gateway] TLS_DOMAIN not set -> TLS disabled"
    exit 0
fi

mkdir -p /var/www/certbot

# port80-extra: csak a plain-HTTP listenerre való dolgok (ACME challenge +
# HTTPS redirect) - NEM a server-extra-ba mennek, mert azt a 443-as blokk is
# includeolja (staging basic auth/noindex/bot-block), és a redirect ott
# végtelen ciklust okozna (https -> https).
cp /etc/nginx/tls-available/port80-extra/50-acme-challenge.conf /etc/nginx/conf.d/port80-extra/

CERT_DIR="/etc/letsencrypt/live/${TLS_DOMAIN}"
if [ -f "${CERT_DIR}/fullchain.pem" ] && [ -f "${CERT_DIR}/privkey.pem" ]; then
    echo "[gateway] TLS_DOMAIN=${TLS_DOMAIN}, certificate found -> enabling HTTPS + redirect"
    cp /etc/nginx/tls-available/port80-extra/60-tls-redirect.conf /etc/nginx/conf.d/port80-extra/
    sed "s#__TLS_DOMAIN__#${TLS_DOMAIN}#g" /etc/nginx/tls-available/tls-server/50-https.conf.template \
        > /etc/nginx/conf.d/tls-server/50-https.conf

    # certbot (separate container, sharing the certs volume) renews on its own
    # schedule but has no way to tell nginx to pick up the new cert - it never
    # touches this container. Reloading periodically is simpler and safer than
    # giving certbot Docker-socket access just to trigger a reload: reload is
    # cheap even when nothing changed, and a cert renews weeks before expiry,
    # so a 12h worst-case delay before pickup is harmless.
    (
        while true; do
            sleep 43200
            nginx -s reload 2>&1 | sed 's/^/[gateway] periodic reload: /'
        done
    ) &
else
    echo "[gateway] TLS_DOMAIN=${TLS_DOMAIN}, no certificate yet -> HTTP-only until the certbot bootstrap runs"
fi
