#!/bin/sh
# Paths
# DO NOT EDIT THESE
NGINX_CONF_PATH=/etc/nginx
NGINX_SITES_CONFIG=/etc/nginx/sites.json
NGINX_SITE_PATH=/etc/nginx/sites.d
NGINX_MODULES_PATH=/usr/local/nginx/modules
NGINX_CERT_PATH=${NGINX_CONF_PATH}/certs
NGINX_WEBROOT_PATH=/app/web
NGINX_CACHE_PATH=/var/cache/nginx
NGINX_LOG_PATH=/var/log/nginx
MAXMIND_PATH=${NGINX_CONF_PATH}/maxmind
ACME_HOME=/app/acme
MODSEC_AUDIT_STORAGE=${MODSEC_AUDIT_STORAGE:-/var/log/nginx/modsecurity/}
MODSEC_DATA_DIR=${MODSEC_AUDIT_STORAGE:-/tmp/modsecurity/data}
MODSEC_TMP_DIR=${MODSEC_TMP_DIR:-/tmp/modsecurity/tmp}
MODSEC_UPLOAD_DIR=${MODSEC_UPLOAD_DIR:-/tmp/modsecurity/upload}
# End Paths & Non Editable section

# Nginx config
# List of IP address which can access sensitive information like status etc.
# Supports comma seperated list example 1.1.1.1,10.0.0.0/24
# If none mentioned then you wont be able to access the sensitive parts!
OPT_NGINX_WHITELIST_IP=${NGINX_WHITELIST_IP:-}

# Max body size (client upload) Can and should be overriden in server block
OPT_NGINX_MAX_BODY_SIZE=${NGINX_MAX_UPLOAD_SIZE:-'100M'}

# Mod Security Config
OPT_MODSEC_CRS_PARANOIA=1
OPT_MODSEC_CRS_BLOCKING_PARANOIA=1
OPT_MODSEC_CRS_EXECUTING_PARANOIA=${CRS_PARANOIA}
OPT_MODSEC_CRS_DETECTION_PARANOIA=${CRS_BLOCKING_PARANOIA}
OPT_MODSEC_CRS_ENFORCE_BODYPROC_URLENCODED=1
OPT_MODSEC_CRS_VALIDATE_UTF8_ENCODING=0
OPT_MODSEC_CRS_ANOMALY_INBOUND=5
OPT_MODSEC_CRS_ANOMALY_OUTBOUND=4
OPT_MODSEC_CRS_ALLOWED_METHODS='GET POST PUT PATCH HEAD OPTIONS DELETE'
OPT_MODSEC_CRS_ALLOWED_REQUEST_CONTENT_TYPE='|application/x-www-form-urlencoded| |multipart/form-data| |multipart/related| |text/xml| |application/xml| |application/soap+xml| |application/json| |application/cloudevents+json| |application/cloudevents-batch+json|'
OPT_MODSEC_CRS_ALLOWED_REQUEST_CONTENT_TYPE_CHARSET='utf-8|iso-8859-1|iso-8859-15|windows-1252' 
OPT_MODSEC_CRS_ALLOWED_HTTP_VERSIONS='HTTP/1.0 HTTP/1.1 HTTP/2 HTTP/2.0' 
OPT_MODSEC_CRS_RESTRICTED_EXTENSIONS='.asa/ .asax/ .ascx/ .axd/ .backup/ .bak/ .bat/ .cdx/ .cer/ .cfg/ .cmd/ .com/ .config/ .conf/ .cs/ .csproj/ .csr/ .dat/ .db/ .dbf/ .dll/ .dos/ .htr/ .htw/ .ida/ .idc/ .idq/ .inc/ .ini/ .key/ .licx/ .lnk/ .log/ .mdb/ .old/ .pass/ .pdb/ .pol/ .printer/ .pwd/ .rdb/ .resources/ .resx/ .sql/ .swp/ .sys/ .vb/ .vbs/ .vbproj/ .vsdisco/ .webinfo/ .xsd/ .xsx/'
OPT_MODSEC_CRS_RESTRICTED_HEADERS='/content-encoding/ /proxy/ /lock-token/ /content-range/ /if/ /x-http-method-override/ /x-http-method/ /x-method-override/'
OPT_MODSEC_CRS_STATIC_EXTENSIONS='/.jpg/ /.jpeg/ /.png/ /.gif/ /.js/ /.css/ /.ico/ /.svg/ /.webp/'
OPT_MODSEC_CRS_MAX_NUM_ARGS='unlimited'
OPT_MODSEC_CRS_ARG_NAME_LENGTH='unlimited'
OPT_MODSEC_CRS_ARG_LENGTH='unlimited'
OPT_MODSEC_CRS_TOTAL_ARG_LENGTH='unlimited'
OPT_MODSEC_CRS_MAX_FILE_SIZE='unlimited'
OPT_MODSEC_CRS_COMBINED_FILE_SIZES='unlimited'
OPT_MODSEC_CRS_ENABLE_TEST_MARKER=0
OPT_MODSEC_CRS_REPORTING_LEVEL=2
OPT_MODSEC_AUDIT_ENGINE="RelevantOnly"
OPT_MODSEC_AUDIT_LOG_FORMAT=JSON
OPT_MODSEC_AUDIT_LOG_TYPE=Serial
OPT_MODSEC_AUDIT_LOG=/var/log/nginx/$server_name/audit.log
OPT_MODSEC_AUDIT_LOG_PARTS='ABIJDEFHZ'
OPT_MODSEC_AUDIT_STORAGE=/var/log/nginx/modsecurity/
OPT_MODSEC_DATA_DIR=/tmp/modsecurity/data
OPT_MODSEC_DEBUG_LOG=/dev/null
OPT_MODSEC_DEBUG_LOGLEVEL=0
OPT_MODSEC_DEFAULT_PHASE1_ACTION="phase:1,pass,log,tag:'\${MODSEC_TAG}'"
OPT_MODSEC_DEFAULT_PHASE2_ACTION="phase:2,pass,log,tag:'\${MODSEC_TAG}'"
OPT_MODSEC_PCRE_MATCH_LIMIT_RECURSION=100000
OPT_MODSEC_PCRE_MATCH_LIMIT=100000
OPT_MODSEC_REQ_BODY_ACCESS=on
OPT_MODSEC_REQ_BODY_LIMIT=13107200
OPT_MODSEC_REQ_BODY_LIMIT_ACTION="Reject"
OPT_MODSEC_REQ_BODY_JSON_DEPTH_LIMIT=512
OPT_MODSEC_REQ_BODY_NOFILES_LIMIT=131072
OPT_MODSEC_RESP_BODY_ACCESS=on
OPT_MODSEC_RESP_BODY_LIMIT=1048576
OPT_MODSEC_RESP_BODY_LIMIT_ACTION="ProcessPartial"
OPT_MODSEC_RESP_BODY_MIMETYPE="text/plain text/html text/xml"
OPT_MODSEC_RULE_ENGINE=on
OPT_MODSEC_STATUS_ENGINE="Off"
OPT_MODSEC_TAG=modsecurity
OPT_MODSEC_TMP_DIR=/tmp/modsecurity/tmp
OPT_MODSEC_TMP_SAVE_UPLOADED_FILES="on"
OPT_MODSEC_UPLOAD_DIR=/tmp/modsecurity/upload

# MAXMIND CONFIG
OPT_MAXMIND_KEY=${MAXMIND_KEY}
# Overload with secrets if it exists
if [ -f /run/secrets/MAXMIND_KEY ]; then
  OPT_MAXMIND_KEY=$(cat /run/secrets/MAXMIND_KEY)
fi
OPT_MAXMIND_EDITION=${MAXMIND_EDITION:-'geolite2'}
OPT_MAXMIND_DATABASE=${MAXMIND_DATABASE:-'city'}

# SSL Config
OPT_SSL_KEY_LENGTH=${SSL_KEY_LENGTH:-4096}
OPT_ACME_EMAIL=${ACME_EMAIL:-}
OPT_ACME_SERVER=${ACME_SERVER:-letsencrypt}
OPT_ACME_THUMBPRINT=