ARG ALPINE_VERSION \
    NGINX_VERSION \
    YAJL_VERSION=2.1.0 \
    MOD_SECURITY_VERSION=3.0.6

FROM tundrasoft/alpine:${ALPINE_VERSION} as build

ARG ALPINE_VERSION \
    NGINX_VERSION \
    YAJL_VERSION \
    MOD_SECURITY_VERSION

USER root

RUN set -eux; \
    apk add --no-cache \
      openssl \
      openssl-dev \
      pcre-dev \
      zlib-dev \
      geoip-dev \
      libmaxminddb-dev \
      libxslt-dev \
      automake \
      autoconf \
      linux-headers \
      libtool \
      wget \
      build-base \
      git \
      ruby \
      make \
      cmake;

WORKDIR /tmp

RUN set -eux; \
    git clone https://github.com/lloyd/yajl --branch ${YAJL_VERSION} --depth 1; \
    cd yajl; \
    ./configure; \
    make install; \
    strip /usr/local/lib/libyajl*.so*;

RUN set -eux; \
    git clone https://github.com/SpiderLabs/ModSecurity --branch v${MOD_SECURITY_VERSION} --depth 1; \
    cd ModSecurity; \
    ./build.sh; \
    git submodule init; \
    git submodule update; \
    ./configure --with-yajl=/tmp/yajl/build/yajl-${YAJL_VERSION}/ --with-geoip; \
    make -j 6 install; \
    strip /usr/local/modsecurity/lib/lib*.so*;

RUN set -eux; \
    git clone -b master --depth 1 https://github.com/slact/nchan.git; \
    git clone -b master --depth 1 https://github.com/Lax/traffic-accounting-nginx-module.git; \
    git clone -b master --depth 1 https://github.com/leev/ngx_http_geoip2_module.git; \
    git clone -b master --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git; \
    git clone -b master --depth 1 https://github.com/nicholaschiasson/ngx_upstream_jdomain.git; \
    git clone -b master --depth 1 https://github.com/masterzen/nginx-upload-progress-module.git; \
    git clone -b master --depth 1 https://github.com/aperezdc/ngx-fancyindex.git; \
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O nginx-${NGINX_VERSION}.tar.gz; \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz; \
    cd ./nginx-${NGINX_VERSION}; \
    ./configure --with-compat \
      --add-dynamic-module=../nchan \
      --add-dynamic-module=../traffic-accounting-nginx-module \
      --add-dynamic-module=../ngx_http_geoip2_module \
      --add-dynamic-module=../ModSecurity-nginx \
      --add-dynamic-module=../ngx_upstream_jdomain \
      --add-dynamic-module=../nginx-upload-progress-module \
      --add-dynamic-module=../ngx-fancyindex; \
    make -j 6 modules; \
    strip objs/*.so; \
    mkdir /modules; \
    cp objs/*.so /modules/; \
    cd /modules;

ADD https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended /tmp/modsecurity.conf
ADD https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping /tmp/unicode.mapping

# Build final image
ARG ALPINE_VERSION \
    NGINX_VERSION \
    YAJL_VERSION \
    MOD_SECURITY_VERSION

FROM tundrasoft/alpine:${ALPINE_VERSION}
LABEL maintainer="Abhinav A V <abhai2k@gmail.com>"

ARG ALPINE_VERSION \
    NGINX_VERSION \
    YAJL_VERSION \
    MOD_SECURITY_VERSION \
    NGINX_PREFIX=/usr/local/nginx \
    NGINX_CONF_DIR=/etc/nginx/ \
    NGINX_MODULES_PATH=/etc/nginx/modules

ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    MAXMIND_KEY=\
    MAXMIND_VERSION="GeoLite2-City" \
    NGINX_WEBROOT=/webroot \
    SSL_PATH=${NGINX_CONF_DIR}/certificates \
    SSL_KEY_LENGTH=4096 \
    ACME_ACCOUNT_EMAIL=\
    ACME_SSL_CA="letsencrypt" \
    SITES=\
    SECURE_SITES=

# USER root

RUN set -eux; \
    apk add --no-cache openssl \
      pcre-dev \
      zlib-dev \
      libmaxminddb \
      curl \
      libxml2 \
      geoip; \
    apk add --no-cache --virtual .build-deps \
      wget \
      git \
      openssl-dev \
      build-base; \
    cd /tmp; \
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O nginx-${NGINX_VERSION}.tar.gz; \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz; \
    cd nginx-${NGINX_VERSION}; \
    ./configure --with-compat \
      --prefix=${NGINX_PREFIX} \
      --conf-path=${NGINX_CONF_DIR}/nginx.conf \
      --modules-path=${NGINX_MODULES_PATH} \
      --http-log-path=/var/log/nginx/access.log \
      --error-log-path=/var/log/nginx/error.log \
      --sbin-path=/usr/bin/nginx \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/run/nginx.lock \
      --user=${UNAME} \
      --group=${GNAME} \
      --with-http_ssl_module \
      --with-http_gzip_static_module \
      --with-http_v2_module \
      --with-http_stub_status_module \
      --with-http_realip_module \
      --with-stream=dynamic \
      --without-http_ssi_module; \
    make install; \
    cd /tmp; \
    wget https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh -O acme.sh; \
    chmod +x acme.sh; \
    ./acme.sh --install \
      --home /acme \
      --config-home /acme/config \
      --cert-home ${SSL_PATH} \
      --accountemail "rand@email.com"; \
    apk del .build-deps -r; \
    rm -f /acme/config/account.conf; \
    rm -rf /tmp/*;

COPY --from=build /usr/local/modsecurity/lib/libmodsecurity.so.${MOD_SECURITY_VERSION} /usr/local/modsecurity/lib/
COPY --from=build /usr/local/lib/libyajl.so.${YAJL_VERSION} /usr/local/lib/
COPY --from=build /modules/*.so ${NGINX_MODULES_PATH}/
COPY --from=build /tmp/modsecurity.conf ${NGINX_CONF_DIR}/modsecurity/
COPY --from=build /tmp/unicode.mapping ${NGINX_CONF_DIR}/modsecurity/

COPY /rootfs/ /

ADD crontab /etc/crontabs
RUN chown ${USER}:${GROUP} -R /scripts; \
    crontab /etc/crontabs/crontab

RUN ln -s /usr/local/modsecurity/lib/libmodsecurity.so.${MOD_SECURITY_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3.0; \
    ln -s /usr/local/modsecurity/lib/libmodsecurity.so.${MOD_SECURITY_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3; \
    ln -s /usr/local/modsecurity/lib/libmodsecurity.so.${MOD_SECURITY_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so; \
    ln -s /usr/local/lib/libyajl.so.${YAJL_VERSION} /usr/local/lib/libyajl.so; \
    ln -s /usr/local/lib/libyajl.so.${YAJL_VERSION} /usr/local/lib/libyajl.so.2;

#     mkdir -p /tmp/modsecurity/data; \
#     mkdir -p /tmp/modsecurity/upload; \
#     mkdir -p /tmp/modsecurity/tmp; \
#     mkdir -p /usr/local/modsecurity; \
#     mkdir -p /etc/nginx/ssl_certificates; \
#     mkdir -p /etc/nginx/html/.well-known/acme-challenge; 

# USER ${UNAME}

VOLUME [ "/etc/nginx", "/webroot", "/acme/config" ]

EXPOSE 80 443