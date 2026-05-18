ARG OPENRESTY_VERSION=1.29.2.3
ARG OPENRESTY_IMAGE_REVISION=0
ARG LUA_RESTY_OPENIDC_VERSION=1.8.0-1

# Keep LuaRocks in the builder stage only; the runtime image only needs OpenResty
# plus the installed Lua modules.
FROM openresty/openresty:${OPENRESTY_VERSION}-${OPENRESTY_IMAGE_REVISION}-alpine-fat AS build

ARG LUA_RESTY_OPENIDC_VERSION

RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-openidc ${LUA_RESTY_OPENIDC_VERSION}

FROM openresty/openresty:${OPENRESTY_VERSION}-${OPENRESTY_IMAGE_REVISION}-alpine

ARG UID=101
ARG GID=101

COPY --from=build /usr/local/openresty/site /usr/local/openresty/site
COPY --from=build /usr/local/openresty/luajit/share/lua/5.1 /usr/local/openresty/luajit/share/lua/5.1
COPY --from=build /usr/local/openresty/luajit/lib/lua/5.1 /usr/local/openresty/luajit/lib/lua/5.1

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

# for å tillate lua-script å få tak i spesifikke miljøvariabler
RUN printf '%s\n' \
    'env AZURE_APP_WELL_KNOWN_URL;' \
    'env AZURE_APP_CLIENT_ID;' \
    'env WELL_KNOWN_URI;' \
    'env HTTP_PROXY;' \
    'env HTTPS_PROXY;' \
    'env NO_PROXY;' \
    'env GANDALF_BASE_URL;' \
    'env STS_BASE_URL;' \
    'env CICS_BASE_URL;' \
    >> /usr/local/openresty/nginx/conf/nginx.conf

COPY proxy.conf /etc/nginx/conf.d/default.conf
COPY jwt.lua /usr/local/openresty/nginx/

USER $UID
