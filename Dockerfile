FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY staging-available /etc/nginx/staging-available
COPY docker-entrypoint.d/40-staging-config.sh /docker-entrypoint.d/40-staging-config.sh

RUN mkdir -p /etc/nginx/conf.d/http-extra /etc/nginx/conf.d/server-extra \
    && chmod +x /docker-entrypoint.d/40-staging-config.sh

EXPOSE 80
