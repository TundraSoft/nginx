<!-- https://github.com/coreruleset/modsecurity-crs-docker/blob/develop/nginx/Dockerfile-alpine-->

# TundraSoft - Nginx


[![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/TundraSoft/nginx/build-docker.yml?event=push&logo=github)](https://github.com/TundraSoft/nginx/actions/workflows/build-docker.yml)
[![GitHub issues](https://img.shields.io/github/issues-raw/TundraSoft/nginx.svg)](https://github.com/TundraSoft/nginx/issues)
[![GitHub PRs](https://img.shields.io/github/issues-pr-raw/TundraSoft/nginx.svg)](https://github.com/tundrasoft/nginx/pulls) 
[![License](https://img.shields.io/github/license/TundraSoft/nginx.svg)](https://github.com/TundraSoft/nginx/blob/master/LICENSE)

[![Repo size](https://img.shields.io/github/repo-size/tundrasoft/nginx)](#)
[![Docker image size](https://img.shields.io/docker/image-size/tundrasoft/nginx)](https://hub.docker.com/r/tundrasoft/nginx)
[![Docker Pulls](https://img.shields.io/docker/pulls/tundrasoft/nginx.svg)](https://hub.docker.com/r/tundrasoft/nginx)


Docker image for Nginx web server. It contains few custom modules pre-installed which pack a bit more of a punch
to the nginx server

## Installed Components

## Core Modules
```bash
--with-http_ssl_module
--with-http_gzip_static_module
--with-http_v2_module
--with-http_stub_status_module
--with-http_realip_module https://nginx.org/en/docs/http/ngx_http_realip_module.html
--with-http_addition_module https://nginx.org/en/docs/http/ngx_http_addition_module.html
--with-http_xslt_module https://nginx.org/en/docs/http/ngx_http_xslt_module.html 
--with-stream https://nginx.org/en/docs/stream/ngx_stream_core_module.html
--without-http_ssi_module
```

## Third Party

### Nginx upstream jDomain (dynamic)

Use domain names instead of ip address in upstream. https://github.com/nicholaschiasson/ngx_upstream_jdomain

### Fancy Index (dynamic)

A prettier Index page generator https://github.com/aperezdc/ngx-fancyindex

### GeoIP2 (dynamic)

MaxMind GEO IP 2 database usage in nginx https://github.com/leev/ngx_http_geoip2_module

### Traffic accounting (dynamic)

Account for traffic in realtime https://github.com/Lax/traffic-accounting-nginx-module

### NChan (dynamic)

A pub/sub module built in nginx https://github.com/slact/nchan

### ModSecurity (dynamic)

A fast and reliable WAF for nginx https://github.com/spiderlabs/modsecurity/ & https://github.com/SpiderLabs/ModSecurity-nginx

### Upload Progress (dynamic)

Add file upload progress support in nginx https://github.com/masterzen/nginx-upload-progress-module

### Nginx upstream fair TODO

A more enhanced roundrobin upstream load balancer https://github.com/gnosek/nginx-upstream-fair

### LDAP Authentication TODO

Add LDAP authentication support in nginx https://github.com/kvspb/nginx-auth-ldap


## Others

### ACME

Installed ACME.sh script to autogenerate SSL for using letsencrypt or equivalent. https://github.com/acmesh-official/acme.sh

### Auto Reload

Auto reloads nginx config when it detects changes in the same. It will only reload if the changes are valid. 

**NOTE** Upon restart, if the config is invalid, then the service will not start!


## ENV Variables

### MAXMIND_KEY

This is the license key provided by maxmind site to download updates for GeoIP2 database. Defaults to null.

### MAXMIND_VERSION

The version to download. Defaults to null. Accepted values:
- GeoIP2Lite-City
- GeoIP2Lite-Country
- GeoIP2-City
- GeoIP2-Country

### NGINX_WEBROOT

The webroot path for NGINX. Defaults to /webroot. There should not be any reason to change this

### SSL_PATH

Path where the SSL certificates are stored. Defaults to /etc/nginx/certificates

### SSL_KEY_LENGTH

The key length to be used to generate SSL certificate. Defaults to 4096bit key

### ACME_ACCOUNT_EMAIL

The email id to be used by ACME to register and generate SSL certificates. Defaults to null

### ACME_SSL_CA

The certificate authority to use to generate the certificate. Defaults to letsencrypt. See [ACME](https://github.com/acmesh-official/acme.sh) documentation for possible options.

### SITES

List (csv) of sites to "deploy" or create. This is a helper variable to create sites with default configuration. 

Do note, removing a site from env variable *does not* mean the site is disabled. You will have to manually remove the same from config.

### SECURE_SITES

List (csv) of sites to "deploy" or create with SSL certificate. This is a helper variable to create sites with default configuration. 

Do note, removing a site from env variable *does not* mean the site is disabled. You will have to manually remove the same from config.


## Configuring

By default, a base nginx config file is created with following dynamic modules enabled:
- Nginx upstream jdomain
- Traffic Accounting

The other modules are disabled/not loaded by default. To enable
- GeoIP2 - ENV variables MAXMIND_KEY *and* MAXMIND_VERSION needs to be set
- Fancy Index - This can be enabled on a site level. Follow sample template provided in templates folder
- NChan - This can be enabled on a site level. Follow sample template provided in templates folder
- ModSecurity - This can be enabled on a site level. Follow sample template provided in templates folder
- Upload Progress - This can be enabled on a site 

## Build
```docker
docker build . --cpuset-cpus 0-3  --no-cache --build-arg NGINX_VERSION=1.25.1 --build-arg ALPINE_VERSION=latest --platform=linux/x86_64 -t tundrasoft/nginx

docker build . --cpuset-cpus 0-3  --build-arg NGINX_VERSION=1.25.1 --build-arg ALPINE_VERSION=latest --platform=linux/x86_64 -t tundrasoft/nginx

docker build . --cpuset-cpus 0-3 --no-cache --build-arg NGINX_VERSION=1.25.1 --build-arg ALPINE_VERSION=latest --platform=linux/arm/v7 -t tundrasoft/nginx

```

