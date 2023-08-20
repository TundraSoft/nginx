ARG ALPINE_VERSION \
    CRS_VERSION=3.3.5 \
    MOD_SECURITY_VERSION=3.0.9 \
    NGINX_VERSION

# we use latest only as this is for build
FROM tundrasoft/alpine:latest as build

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
      lmdb-dev \
      linux-headers \
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
    strip /usr/local/modsecurity/lib/lib*.so*; \
    wget --quiet https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended \
        -O /tmp/modsecurity.conf; \
    wget --quiet https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping \
        -O /tmp/unicode.mapping;

# ADD https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended /tmp/modsecurity.conf
# ADD https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping /tmp/unicode.mapping

RUN set -eux; \
    mkdir /modules; \
    git clone -b master --depth 1 https://github.com/slact/nchan.git; \
    git clone -b master --depth 1 https://github.com/leev/ngx_http_geoip2_module.git; \
    git clone -b master --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git; \
    git clone -b master --depth 1 https://github.com/nicholaschiasson/ngx_upstream_jdomain.git; \
    git clone -b master --depth 1 https://github.com/openresty/headers-more-nginx-module.git; \
    git clone -b master --depth 1 https://github.com/dstroma/nginx-upload-progress-module.git; \
    git clone -b master --depth 1 https://github.com/aperezdc/ngx-fancyindex.git; \
    # Below are under test\
    git clone -b master --depth 1 https://github.com/cinquemb/nginx-upstream-serverlist.git; \
    # git clone -b master --depth 1 https://github.com/hnlq715/status-nginx-module.git; \
    git clone --depth 1 https://github.com/vozlt/nginx-module-vts.git; \
    # git clone --depth 1 https://github.com/cubicdaiya/ngx_dynamic_upstream.git;\
    git clone --depth 1 https://github.com/nginx-modules/ngx_http_hmac_secure_link_module.git; \
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O nginx-${NGINX_VERSION}.tar.gz; \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz; \
    cd ./nginx-${NGINX_VERSION}; \
    ./configure --with-compat \
      --with-stream \
      --add-dynamic-module=../nchan \
      --add-dynamic-module=../ngx_http_geoip2_module \
      --add-dynamic-module=../ModSecurity-nginx \
      --add-dynamic-module=../ngx_upstream_jdomain \
      --add-dynamic-module=../headers-more-nginx-module \
      --add-dynamic-module=../nginx-upload-progress-module \
      --add-dynamic-module=../ngx-fancyindex \
      --add-dynamic-module=../nginx-upstream-serverlist \
      --add-dynamic-module=../nginx-module-vts \
      --add-dynamic-module=../ngx_http_hmac_secure_link_module; \
    make -j$(nproc) modules; \
    strip objs/*.so; \
    cp objs/*.so /modules/; \
    rm -rf objs/*;

# Core Rule set
FROM tundrasoft/alpine:latest as coreruleset

ARG CRS_VERSION

# hadolint ignore=DL3008,SC2016
RUN set -eux; \
    apk add --no-cache \
    ca-certificates \
    curl \
    gnupg; \
    mkdir /opt/owasp-crs; \
    curl -SL https://github.com/coreruleset/coreruleset/archive/v${CRS_VERSION}.tar.gz -o v${CRS_VERSION}.tar.gz; \
    curl -SL https://github.com/coreruleset/coreruleset/releases/download/v${CRS_VERSION}/coreruleset-${CRS_VERSION}.tar.gz.asc -o coreruleset-${CRS_VERSION}.tar.gz.asc; \
    gpg --fetch-key https://coreruleset.org/security.asc; \
    gpg --verify coreruleset-${CRS_VERSION}.tar.gz.asc v${CRS_VERSION}.tar.gz; \
    tar -zxf v${CRS_VERSION}.tar.gz --strip-components=1 -C /opt/owasp-crs; \
    rm -f v${CRS_VERSION}.tar.gz coreruleset-${CRS_VERSION}.tar.gz.asc; \
    mv -v /opt/owasp-crs/crs-setup.conf.example /opt/owasp-crs/crs-setup.conf; \
    rm -rf /opt/owasp-crs/*.md /opt/owasp-crs/docs /opt/owasp-crs/INSTALL /opt/owasp-crs/KNOWN_BUGS /opt/owasp-crs/LICENSE /opt/owasp-crs/tests;

# Final Build
FROM tundrasoft/alpine:${ALPINE_VERSION}

LABEL maintainer="Abhinav A V <abhai2k@gmail.com>"

ARG ALPINE_VERSION \
    CRS_VERSION \
    MOD_SECURITY_VERSION \
    NGINX_CONF_DIR=/etc/nginx \
    NGINX_MODULES_PATH=/usr/local/nginx/modules \
    NGINX_PREFIX=/usr/local/nginx \
    NGINX_VERSION

ENV ACME_EMAIL=\
    ACME_SERVER='letsencrypt' \
    CRS_PARANOIA=1\
    CRS_BLOCKING_PARANOIA=1\
    CRS_EXECUTING_PARANOIA=${CRS_PARANOIA}\
    CRS_DETECTION_PARANOIA=${CRS_BLOCKING_PARANOIA}\
    CRS_ENFORCE_BODYPROC_URLENCODED=1\
    CRS_VALIDATE_UTF8_ENCODING=0\
    CRS_ANOMALY_INBOUND=5\
    CRS_ANOMALY_OUTBOUND=4\
    CRS_ALLOWED_METHODS='GET POST PUT PATCH HEAD OPTIONS DELETE'\
    CRS_ALLOWED_REQUEST_CONTENT_TYPE='|application/x-www-form-urlencoded| |multipart/form-data| |multipart/related| |text/xml| |application/xml| |application/soap+xml| |application/json| |application/cloudevents+json| |application/cloudevents-batch+json|' \
    CRS_ALLOWED_REQUEST_CONTENT_TYPE_CHARSET='utf-8|iso-8859-1|iso-8859-15|windows-1252' \
    CRS_ALLOWED_HTTP_VERSIONS='HTTP/1.0 HTTP/1.1 HTTP/2 HTTP/2.0' \
    CRS_RESTRICTED_EXTENSIONS='.asa/ .asax/ .ascx/ .axd/ .backup/ .bak/ .bat/ .cdx/ .cer/ .cfg/ .cmd/ .com/ .config/ .conf/ .cs/ .csproj/ .csr/ .dat/ .db/ .dbf/ .dll/ .dos/ .htr/ .htw/ .ida/ .idc/ .idq/ .inc/ .ini/ .key/ .licx/ .lnk/ .log/ .mdb/ .old/ .pass/ .pdb/ .pol/ .printer/ .pwd/ .rdb/ .resources/ .resx/ .sql/ .swp/ .sys/ .vb/ .vbs/ .vbproj/ .vsdisco/ .webinfo/ .xsd/ .xsx/' \
    CRS_RESTRICTED_HEADERS='/content-encoding/ /proxy/ /lock-token/ /content-range/ /if/ /x-http-method-override/ /x-http-method/ /x-method-override/' \
    CRS_STATIC_EXTENSIONS='/.jpg/ /.jpeg/ /.png/ /.gif/ /.js/ /.css/ /.ico/ /.svg/ /.webp/' \
    CRS_MAX_NUM_ARGS='unlimited' \
    CRS_ARG_NAME_LENGTH='unlimited' \
    CRS_ARG_LENGTH='unlimited' \
    CRS_TOTAL_ARG_LENGTH='unlimited' \
    CRS_MAX_FILE_SIZE='unlimited' \
    CRS_COMBINED_FILE_SIZES='unlimited' \
    CRS_ENABLE_TEST_MARKER=0\
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0\
    CRS_REPORTING_LEVEL=2\
    MAXMIND_DATABASE="city" \
    MAXMIND_EDITION="GeoLite2" \
    MAXMIND_KEY=\
    MAXMIND_PATH="${NGINX_CONF_DIR}/maxmind"\
    MAXMIND_REFRESH='0 0 * * *' \
    MODSEC_AUDIT_ENGINE="RelevantOnly" \
    MODSEC_AUDIT_LOG_FORMAT=JSON \
    MODSEC_AUDIT_LOG_TYPE=Serial \
    MODSEC_AUDIT_LOG=/var/log/nginx/$server_name/audit.log \
    MODSEC_AUDIT_LOG_PARTS='ABIJDEFHZ' \
    MODSEC_AUDIT_STORAGE=/var/log/nginx/modsecurity/ \
    MODSEC_DATA_DIR=/tmp/modsecurity/data \
    MODSEC_DEBUG_LOG=/dev/null \
    MODSEC_DEBUG_LOGLEVEL=0 \
    MODSEC_DEFAULT_PHASE1_ACTION="phase:1,pass,log,tag:'\${MODSEC_TAG}'" \
    MODSEC_DEFAULT_PHASE2_ACTION="phase:2,pass,log,tag:'\${MODSEC_TAG}'" \
    MODSEC_PCRE_MATCH_LIMIT_RECURSION=100000 \
    MODSEC_PCRE_MATCH_LIMIT=100000 \
    MODSEC_REQ_BODY_ACCESS=on \
    MODSEC_REQ_BODY_LIMIT=13107200 \
    MODSEC_REQ_BODY_LIMIT_ACTION="Reject" \
    MODSEC_REQ_BODY_JSON_DEPTH_LIMIT=512 \
    MODSEC_REQ_BODY_NOFILES_LIMIT=131072 \
    MODSEC_RESP_BODY_ACCESS=on \
    MODSEC_RESP_BODY_LIMIT=1048576 \
    MODSEC_RESP_BODY_LIMIT_ACTION="ProcessPartial" \
    MODSEC_RESP_BODY_MIMETYPE="text/plain text/html text/xml" \
    MODSEC_RULE_ENGINE=on \
    MODSEC_STATUS_ENGINE="Off" \
    MODSEC_TAG=modsecurity \
    MODSEC_TMP_DIR=/tmp/modsecurity/tmp \
    MODSEC_TMP_SAVE_UPLOADED_FILES="on" \
    MODSEC_UPLOAD_DIR=/tmp/modsecurity/upload \
    NGINX_CACHE_DIR=/var/cache/nginx \
    NGINX_RELOAD='*/10 * * * *' \
    NGINX_CERT_PATH=${NGINX_CONF_DIR}/certs \
    NGINX_MAX_UPLOAD_SIZE='100M'\
    NGINX_WEBROOT=/app \
    NGINX_WHITELIST_IP=\
    SSL_KEY_LENGTH=4096


RUN set -eux; \
    apk add --no-cache \
        curl \
        geoip \
        libfuzzy2 \
        libmaxminddb \
        libstdc++ \
        libxml2 \
        lmdb \
        openssl \
        pcre \
        pcre2 \
        sed \
        yajl; \
    apk add --no-cache --virtual .build-deps \
        build-base \
        curl-dev \
        libxml2-dev \
        openssl-dev \
        pcre-dev; \
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
      --user=tundra \
      --group=tundra \
      --with-http_ssl_module \
      --with-http_gzip_static_module \
      --with-http_v2_module \
      --with-http_stub_status_module \
      --with-http_realip_module \
      --with-stream=dynamic \
      --without-http_ssi_module; \
    make -j$(nproc) install; \
    apk del .build-deps -r; \
    rm -rf /etc/nginx/*.default; \
    cd /tmp; \
    wget https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh -O acme.sh; \
    chmod +x acme.sh; \
    ./acme.sh --install \
      --home /app/acme \
      --log /var/log/nginx/acme.log; \
    rm -rf /tmp/*; \
    rm -rf /etc/nginx;

COPY /rootfs/ /

COPY --from=build /usr/local/modsecurity/lib/libmodsecurity.so.${MOD_SECURITY_VERSION} /usr/local/modsecurity/lib/
COPY --from=build /modules/*.so /${NGINX_MODULES_PATH}/
COPY --from=build /tmp/modsecurity.conf ${NGINX_CONF_DIR}/conf.d/modsecurity/
COPY --from=build /tmp/unicode.mapping ${NGINX_CONF_DIR}/conf.d/modsecurity/
COPY --from=coreruleset /opt/owasp-crs /etc/nginx/conf.d/modsecurity/owasp

# We move crs-setup.conf to templates for now as we set the /etc/nginx as a volume which means once updated the file cannot be updated
RUN mv /etc/nginx/conf.d/modsecurity/owasp/crs-setup.conf /templates/crs-setup.conf.template; \
    ln -s /usr/local/modsecurity/lib/libmodsecurity.so.${MOD_SECURITY_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3.0; \
    ln -s /usr/local/modsecurity/lib/libmodsecurity.so.${MOD_SECURITY_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3; \
    ln -s /usr/local/modsecurity/lib/libmodsecurity.so.${MOD_SECURITY_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so;

# /etc/nginx is Config /app is the webroot /var/log/nginx is the log path
VOLUME [ "/etc/nginx", "/app", "/var/log/nginx" ]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s CMD /usr/bin/healthcheck.sh

EXPOSE 80 443