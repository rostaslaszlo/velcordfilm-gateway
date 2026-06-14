#!/bin/sh
# A nginx hivatalos image automatikusan lefuttatja az /docker-entrypoint.d/*.sh
# scripteket induláskor, mielőtt elindítaná az nginx-et.
#
# ENVIRONMENT=production (alapértelmezett) → staging extra config kihagyva
# ENVIRONMENT=bármi más (pl. staging)      → basic auth + noindex + AI bot tiltás bekapcsolva
set -e

if [ "${ENVIRONMENT:-production}" != "production" ]; then
    echo "[gateway] ENVIRONMENT=${ENVIRONMENT} -> staging extra config aktiválva"
    cp /etc/nginx/staging-available/http-extra/*.conf   /etc/nginx/conf.d/http-extra/   2>/dev/null || true
    cp /etc/nginx/staging-available/server-extra/*.conf /etc/nginx/conf.d/server-extra/ 2>/dev/null || true

    # docker-compose-ban a .htpasswd-t a host mountolja be. Olyan
    # környezetekben (pl. Azure Container Apps), ahol nincs volume mount,
    # a HTPASSWD_CONTENT env várból írjuk ki induláskor.
    if [ -n "${HTPASSWD_CONTENT:-}" ] && [ ! -f /etc/nginx/.htpasswd ]; then
        printf '%s\n' "${HTPASSWD_CONTENT}" > /etc/nginx/.htpasswd
        echo "[gateway] .htpasswd írva HTPASSWD_CONTENT env várból"
    fi
else
    echo "[gateway] ENVIRONMENT=production -> staging extra config kihagyva"
fi
