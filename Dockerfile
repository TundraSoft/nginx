ARG ALPINE_VERSION=3.19 \
    MOD_SECURITY_VERSION=3.0.13 \
    CRS_VERSION=4.7.0 \
    NGINX_VERSION=1.27.2

# we use latest only as this is for build
FROM tundrasoft/alpine:new-build-${ALPINE_VERSION} AS build

ARG ALPINE_VERSION \
    CRS_VERSION \
    MOD_SECURITY_VERSION \
    NGINX_VERSION

RUN set -eux; \
    apk add --no-cache \
      autoconf \
      automake \
      build-base \
      cmake \
      curl-dev \
      gcc \
      geoip-dev \
      git \
      libc-dev \
      libfuzzy2-dev \
      libmaxminddb-dev \
      libtool \
      libxslt-dev \
      linux-headers \
      lmdb-dev \
      make \
      openssl \
      openssl-dev \
      pcre-dev \
      pcre2-dev \
      ruby \
      ruby-dev \
      ruby-rake \
      wget \
      yajl \
      yajl-dev \
      zlib-dev;

WORKDIR /tmp

RUN set -eux; \
    git clone https://github.com/SpiderLabs/ModSecurity --branch v${MOD_SECURITY_VERSION} --depth 1; \
    cd ModSecurity; \
    ./build.sh; \
    git submodule init; \
    git submodule update; \
    ./configure  --with-yajl --with-ssdeep --with-lmdb --with-geoip --with-pcre2 --enable-silent-rules; \
    make -j$(nproc) install; \
    strip /usr/local/modsecurity/lib/lib*.so*;

ADD https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz ./nginx-${NGINX_VERSION}.tar.gz

RUN set -eux; \
    mkdir /modules; \
    git clone -b master --depth 1 https://github.com/leev/ngx_http_geoip2_module.git; \
    git clone -b master --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git; \
    git clone -b master --depth 1 https://github.com/openresty/headers-more-nginx-module.git; \
    git clone --depth 1 https://github.com/cubicdaiya/ngx_dynamic_upstream.git; \
    git clone --depth 1 https://github.com/vozlt/nginx-module-vts.git; \
    git clone --depth 1 https://github.com/nginx-modules/ngx_http_hmac_secure_link_module.git; \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz; \
    cd ./nginx-${NGINX_VERSION}; \
    ./configure --with-compat \
      --with-stream \
      --add-dynamic-module=../ngx_http_geoip2_module \
      --add-dynamic-module=../ModSecurity-nginx \
      --add-dynamic-module=../headers-more-nginx-module \
      --add-dynamic-module=../ngx_dynamic_upstream \
      --add-dynamic-module=../nginx-module-vts \
      --add-dynamic-module=../ngx_http_hmac_secure_link_module; \
    make -j$(nproc) modules; \
    strip objs/*.so; \
    cp objs/*.so /modules/; \
    rm -rf objs/*;

# Core Rule set
FROM tundrasoft/alpine:new-build-${ALPINE_VERSION} AS coreruleset

ARG CRS_VERSION

ADD https://github.com/coreruleset/coreruleset/archive/v${CRS_VERSION}.tar.gz ./v${CRS_VERSION}.tar.gz
ADD https://github.com/coreruleset/coreruleset/releases/download/v${CRS_VERSION}/coreruleset-${CRS_VERSION}.tar.gz.asc ./coreruleset-${CRS_VERSION}.tar.gz.asc

RUN set -eux; \
    apk add --no-cache \
    ca-certificates \
    curl \
    gnupg; \
    mkdir /opt/owasp-crs; \
    gpg --fetch-key https://coreruleset.org/security.asc; \
    gpg --verify coreruleset-${CRS_VERSION}.tar.gz.asc v${CRS_VERSION}.tar.gz; \
    tar -zxf v${CRS_VERSION}.tar.gz --strip-components=1 -C /opt/owasp-crs; \
    rm -f v${CRS_VERSION}.tar.gz coreruleset-${CRS_VERSION}.tar.gz.asc; \
    rm -rf /opt/owasp-crs/*.md \
        /opt/owasp-crs/docs \
        /opt/owasp-crs/INSTALL \
        /opt/owasp-crs/KNOWN_BUGS \
        /opt/owasp-crs/LICENSE \
        /opt/owasp-crs/tests;

# Final image
FROM tundrasoft/alpine:new-build-${ALPINE_VERSION}

LABEL maintainer="Abhinav A V <36784+abhai2k@users.noreply.github.com>"

ARG ALPINE_VERSION \
    CRS_VERSION \
    MOD_SECURITY_VERSION \
    MODSEC_AUDIT_STORAGE=/var/log/nginx/modsec_audit \
    MODSEC_DATA_DIR=/tmp/modsecurity/data \
    MODSEC_TMP_DIR=/tmp/modsecurity/tmp \
    MODSEC_UPLOAD_DIR=/tmp/modsecurity/upload \
    NGINX_CACHE_PATH=/var/cache/nginx \
    NGINX_CONF_PATH=/etc/nginx \
    NGINX_LOG_PATH=/var/log/nginx \
    NGINX_MODULES_PATH=/usr/local/nginx/modules \
    NGINX_PREFIX=/usr/local/nginx \
    NGINX_VERSION

ENV MANAGEMENT_NODE=

ADD https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz /tmp/nginx-${NGINX_VERSION}.tar.gz

RUN set -eux; \
    apk add --no-cache \
        curl \
        curl-dev \
        geoip \
        libfuzzy2 \
        libmaxminddb \
        libstdc++ \
        libxml2 \
        libxml2-dev \
        lmdb \
        openssl \
        openssl-dev \
        pcre \
        pcre-dev \
        pcre2 \
        sed \
        yajl; \
    apk add --no-cache --virtual .build-deps \
        build-base git; \
    cd /tmp; \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz; \
    git clone -b master --depth 1 https://github.com/cinquemb/nginx-upstream-serverlist.git; \
    cd nginx-${NGINX_VERSION}; \
    ./configure --with-compat \
      --prefix=${NGINX_PREFIX} \
      --conf-path=${NGINX_CONF_PATH}/nginx.conf \
      --modules-path=${NGINX_MODULES_PATH} \
      --http-log-path=/var/log/nginx/access.log \
      --error-log-path=/var/log/nginx/error.log \
      --sbin-path=/usr/bin/nginx \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/run/nginx.lock \
      --user=tundra \
      --group=tundra \
      --with-http_ssl_module \
      --with-http_gzip_static_module \
      --with-http_v2_module \
      --with-http_stub_status_module \
      --with-http_realip_module \
      --with-stream=dynamic \
      --without-http_ssi_module \
      --add-module=../nginx-upstream-serverlist; \
    make -j$(nproc) install; \
    apk del .build-deps -r; \
    rm -rf /etc/nginx/*.default; \
    cd /tmp; \
    rm -rf /tmp/*; \
    rm -rf /etc/nginx;

COPY /rootfs/ /

COPY --from=build /usr/local/modsecurity/lib/libmodsecurity.so.${MOD_SECURITY_VERSION} /usr/local/modsecurity/lib/
COPY --from=build /modules/*.so ${NGINX_MODULES_PATH}/
ADD https://raw.githubusercontent.com/nginx/nginx/master/conf/mime.types /etc/nginx/mime.types

ADD https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended ${NGINX_CONF_PATH}/conf.d/modsecurity/modsecurity.conf
ADD https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping ${NGINX_CONF_PATH}/conf.d/modsecurity/unicode.mapping
COPY --from=coreruleset /opt/owasp-crs ${NGINX_CONF_PATH}/conf.d/modsecurity/owasp


# We move crs-setup.conf to templates for now as we set the /etc/nginx as a volume which means once updated the file cannot be updated
RUN ln -s /usr/local/modsecurity/lib/libmodsecurity.so.${MOD_SECURITY_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3.0; \
    ln -s /usr/local/modsecurity/lib/libmodsecurity.so.${MOD_SECURITY_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3; \
    ln -s /usr/local/modsecurity/lib/libmodsecurity.so.${MOD_SECURITY_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so; \
    touch /var/run/nginx.pid; \
    openssl dhparam -dsaparam -out ${NGINX_CONF_PATH}/dhparam.pem 4096; \
    mkdir -p ${NGINX_CACHE_PATH} ${NGINX_LOG_PATH} ${MODSEC_AUDIT_STORAGE} ${MODSEC_DATA_DIR} ${MODSEC_TMP_DIR} ${MODSEC_UPLOAD_DIR}; \
    setgroup ${NGINX_PREFIX} ${NGINX_CONF_PATH} ${NGINX_LOG_PATH} ${NGINX_MODULES_PATH} ${MODSEC_AUDIT_STORAGE} ${MODSEC_DATA_DIR} ${MODSEC_TMP_DIR} ${MODSEC_UPLOAD_DIR} /var/run/nginx.pid;

# /etc/nginx is Config /webroot is the webroot /var/log/nginx is the log path
VOLUME [ "/etc/nginx", "/webroot", "/var/log/nginx" ]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s CMD ["/usr/bin/healthcheck.sh"]

EXPOSE 80 443