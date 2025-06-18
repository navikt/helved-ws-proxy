FROM openresty/openresty:1.27.1.1-0-alpine-fat

ARG UID=101
ARG GID=101

# create nginx user/group first, to be consistent throughout docker variants
RUN set -x \
    && addgroup -g $GID -S nginx \
    && adduser -S -D -H -u $UID -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

# nginx user must own the cache and etc directory to write cache and tweak the nginx config \
RUN set -x \
    && sed -i 's,#pid,pid,' /usr/local/openresty/nginx/conf/nginx.conf \
    && sed -i 's,logs/nginx.pid,/tmp/nginx.pid,' /usr/local/openresty/nginx/conf/nginx.conf \
    && sed -i 's,/var/run/openresty/nginx-client-body,/tmp/client_temp,' /usr/local/openresty/nginx/conf/nginx.conf \
    && sed -i 's,/var/run/openresty/nginx-proxy,/tmp/proxy_temp,' /usr/local/openresty/nginx/conf/nginx.conf \
    && sed -i 's,/var/run/openresty/nginx-fastcgi,/tmp/fastcgi_temp,' /usr/local/openresty/nginx/conf/nginx.conf \
    && sed -i 's,/var/run/openresty/nginx-uwsgi,/tmp/uwsgi_temp,' /usr/local/openresty/nginx/conf/nginx.conf \
    && sed -i 's,/var/run/openresty/nginx-scgi,/tmp/scgi_temp,' /usr/local/openresty/nginx/conf/nginx.conf \
    && chown -R $UID:0 /usr/local/openresty/nginx \
    && chmod -R g+w /usr/local/openresty/nginx \
    && chown -R $UID:0 /etc/nginx \
    && chmod -R g+w /etc/nginx

RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-openidc

# for å tillate lua-script å få tak i spesifikke miljøvariabler
RUN echo "env AZURE_APP_WELL_KNOWN_URL;" >> /usr/local/openresty/nginx/conf/nginx.conf
RUN echo "env AZURE_APP_CLIENT_ID;" >> /usr/local/openresty/nginx/conf/nginx.conf
RUN echo "env WELL_KNOWN_URI;" >> /usr/local/openresty/nginx/conf/nginx.conf
RUN echo "env HTTP_PROXY;" >> /usr/local/openresty/nginx/conf/nginx.conf
RUN echo "env HTTPS_PROXY;" >> /usr/local/openresty/nginx/conf/nginx.conf
RUN echo "env NO_PROXY;" >> /usr/local/openresty/nginx/conf/nginx.conf
RUN echo "env GANDALF_BASE_URL;" >> /usr/local/openresty/nginx/conf/nginx.conf
RUN echo "env STS_BASE_URL;" >> /usr/local/openresty/nginx/conf/nginx.conf
RUN echo "env CICS_BASE_URL;" >> /usr/local/openresty/nginx/conf/nginx.conf

COPY proxy.conf /etc/nginx/conf.d/default.conf
COPY jwt.lua /usr/local/openresty/nginx/

USER $UID
