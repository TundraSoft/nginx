<!-- https://github.com/coreruleset/modsecurity-crs-docker/blob/develop/nginx/Dockerfile-alpine-->

# TundraSoft - Nginx


[![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/TundraSoft/nginx/build-docker.yml?event=push&logo=github)](https://github.com/TundraSoft/nginx/actions/workflows/build-docker.yml)
[![GitHub issues](https://img.shields.io/github/issues-raw/TundraSoft/nginx.svg)](https://github.com/TundraSoft/nginx/issues)
[![GitHub PRs](https://img.shields.io/github/issues-pr-raw/TundraSoft/nginx.svg)](https://github.com/tundrasoft/nginx/pulls) 
[![License](https://img.shields.io/github/license/TundraSoft/nginx.svg)](https://github.com/TundraSoft/nginx/blob/master/LICENSE)

[![Repo size](https://img.shields.io/github/repo-size/tundrasoft/nginx)](#)
[![Docker image size](https://img.shields.io/docker/image-size/tundrasoft/nginx)](https://hub.docker.com/r/tundrasoft/nginx)
[![Docker Pulls](https://img.shields.io/docker/pulls/tundrasoft/nginx.svg)](https://hub.docker.com/r/tundrasoft/nginx)

Docker image for Nginx web server. It contains few custom modules pre-installed which pack a bit more of a punch to the nginx server

## Usage
@TODO

### Using Image
@TODO

### Building image

```docker
docker build . --cpuset-cpus 0-3  --no-cache --build-arg NGINX_VERSION=1.25.1 --build-arg ALPINE_VERSION=latest --platform=linux/x86_64 -t tundrasoft/nginx
```

### Volumes

Below volumes are exported by default:
- **/app** - This is the webroot where any static content can be placed. By default 
this will contain the below directories:
    - defaults
        - fancy-index - page index templates
        - 50x.html - Default 50x error page
        - 404.html - Default 404 error page
        - index.htmk - Default index template
    - ${TLD} - Any other domain's webroot
- **/crons** - Folder where cron jobs can be added. By default 2 files are present
    - maxmind_refresh - Refreshes maxmind database
    - nginx_reload - cron to reload nginx if config has changed
- **/etc/nginx** - The main nginx config path. contains all configuration options
    - certs - All certificate files are stored here
    - defaults - Default configuration partials are stored here
        - modsecurity - Modsecurity configuration stored here
    - modules - Dynamic module files are present here *NOTE* DO NOT EDIT THIS
    - sites.d - All site configurations are present here
        - 0-default.conf - (Generated) - Default config blocking undefined access
    - modules.conf - List of enabled modules
    - nginx.conf - Main config file
- **/var/log/nginx** - All logs are stored here

The folder **/etc/nginx/defaults** contains partial configuration files for different modules 
which can be included in your site configuration to activate them. They are meant to be 
generic and not for special use cases (basically a good starting point).

## Configuration

### Site Configuration
@TODO

### Creating new site
@TODO

### Generating SSL (lets encrypt etc)
@TODO

## Modules & Components

### Core Modules

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

### Third Party

#### [Nginx upstream jDomain](https://github.com/nicholaschiasson/ngx_upstream_jdomain)

This module allows you to use a domain name in an upstream block and expect the domain name to be dynamically resolved so your upstream may be resilient to DNS entry updates.

#### [Fancy Index](https://github.com/aperezdc/ngx-fancyindex)

The Fancy Index module makes possible the generation of file listings, like the built-in autoindex module does, but adding a touch of style. This is possible because the module allows a certain degree of customization of the generated content:

- Custom headers, either local or stored remotely.
- Custom footers, either local or stored remotely.
- Add your own CSS style rules.
- Allow choosing to sort elements by name (default), modification time, or size; both ascending (default), or descending.

#### [GeoIP2](https://github.com/leev/ngx_http_geoip2_module)

creates variables with values from the maxmind geoip2 databases based on the client IP (default) or from a specific variable (supports both IPv4 and IPv6)

The module now supports nginx streams and can be used in the same way the http module can be used.

#### [Traffic accounting](https://github.com/Lax/traffic-accounting-nginx-module)

Account for traffic in realtime 
A realtime traffic and status code monitor solution for NGINX, which needs less memory and cpu than other realtime log analyzing solutions. Useful for traffic accounting based on NGINX config logic (by location / server / user-defined-variables).


#### [NChan](https://github.com/slact/nchan)

A pub/sub module built in nginx 
Nchan is a scalable, flexible pub/sub server for the modern web, built as a module for the Nginx web server. It can be configured as a standalone server, or as a shim between your application and hundreds, thousands, or millions of live subscribers. It can buffer messages in memory, on-disk, or via Redis. All connections are handled asynchronously and distributed among any number of worker processes. It can also scale to many Nginx servers with Redis.

#### [ModSecurity](https://github.com/SpiderLabs/ModSecurity-nginx)

The ModSecurity-nginx connector is the connection point between nginx and libmodsecurity (ModSecurity v3). Said another way, this project provides a communication channel between nginx and libmodsecurity. This connector is required to use LibModSecurity with nginx.

The ModSecurity-nginx connector takes the form of an nginx module. The module simply serves as a layer of communication between nginx and ModSecurity.

#### [OWASP Core Rulesets](https://github.com/coreruleset/coreruleset)

The OWASP ModSecurity Core Rule Set (CRS) is a set of generic attack detection rules for use with ModSecurity or compatible web application firewalls. The CRS aims to protect web applications from a wide range of attacks, including the OWASP Top Ten, with a minimum of false alerts.

#### [Upload Progress](https://github.com/masterzen/nginx-upload-progress-module)

Add file upload progress support in nginx

#### [Headers More module](https://github.com/openresty/headers-more-nginx-module)

Set and clear input and output headers...more than "add"!

### Others

#### [ACME](https://github.com/acmesh-official/acme.sh)

Installed ACME.sh script to autogenerate SSL for using letsencrypt or equivalent. 

#### Auto Reload

Auto reloads nginx config when it detects changes in the same. It will only reload if the changes are valid. 

**NOTE** Upon container start/restart, if the config is invalid, then the service will not start!


## ENV Variables

@TODO - To be updated.

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

