FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY staging-available /etc/nginx/staging-available
COPY docker-entrypoint.d/40-staging-config.sh /docker-entrypoint.d/40-staging-config.sh
COPY docker-entrypoint.d/41-upstream-hosts.sh /docker-entrypoint.d/41-upstream-hosts.sh

RUN mkdir -p /etc/nginx/conf.d/http-extra /etc/nginx/conf.d/server-extra \
    && chmod +x /docker-entrypoint.d/40-staging-config.sh /docker-entrypoint.d/41-upstream-hosts.sh

EXPOSE 80
