FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY snippets /etc/nginx/snippets
COPY staging-available /etc/nginx/staging-available
COPY tls-available /etc/nginx/tls-available
COPY docker-entrypoint.d/40-staging-config.sh /docker-entrypoint.d/40-staging-config.sh
COPY docker-entrypoint.d/41-upstream-hosts.sh /docker-entrypoint.d/41-upstream-hosts.sh
COPY docker-entrypoint.d/45-tls.sh /docker-entrypoint.d/45-tls.sh

RUN mkdir -p /etc/nginx/conf.d/http-extra /etc/nginx/conf.d/server-extra /etc/nginx/conf.d/port80-extra /etc/nginx/conf.d/tls-server \
    && chmod +x /docker-entrypoint.d/40-staging-config.sh /docker-entrypoint.d/41-upstream-hosts.sh /docker-entrypoint.d/45-tls.sh

EXPOSE 80 443
