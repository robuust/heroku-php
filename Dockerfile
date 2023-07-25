# Which versions?
ARG PHP_VERSION=8.1.21
ARG REDIS_EXT_VERSION=5.3.7
ARG IMAGICK_EXT_VERSION=3.7.0
ARG PCOV_EXT_VERSION=1.0.11
ARG HTTPD_VERSION=2.4.57
ARG NGINX_VERSION=1.24.0
ARG NODE_VERSION=18.17.0
ARG COMPOSER_VERSION=2.5.8
ARG YARN_VERSION=1.22.19

# Inherit from Heroku's stack
FROM --platform=linux/amd64 robuust/heroku:22 as stage-amd64
ARG PHP_VERSION
ARG REDIS_EXT_VERSION
ARG IMAGICK_EXT_VERSION
ARG PCOV_EXT_VERSION
ARG HTTPD_VERSION
ARG NGINX_VERSION
ARG NODE_VERSION
ARG COMPOSER_VERSION
ARG YARN_VERSION

# Create some needed directories
RUN mkdir -p /app/.heroku/php /app/.heroku/node /app/.profile.d
WORKDIR /app/user

# Install Apache
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-22-stable/apache-$HTTPD_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Nginx
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-22-stable/nginx-$NGINX_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install PHP
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-22-stable/php-$PHP_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-22-stable/extensions/no-debug-non-zts-20210902/redis-$REDIS_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-22-stable/extensions/no-debug-non-zts-20210902/imagick-$IMAGICK_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-22-stable/extensions/no-debug-non-zts-20210902/pcov-$PCOV_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Composer
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-22-stable/composer-$COMPOSER_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Node
RUN curl --silent --location https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz | tar --strip-components=1 -xz -C /app/.heroku/node

# Inherit from Heroku's stack
FROM --platform=linux/arm64 robuust/heroku:22 as stage-arm64
ARG PHP_VERSION
ARG REDIS_EXT_VERSION
ARG IMAGICK_EXT_VERSION
ARG PCOV_EXT_VERSION
ARG HTTPD_VERSION
ARG NGINX_VERSION
ARG NODE_VERSION
ARG COMPOSER_VERSION
ARG YARN_VERSION

# Create some needed directories
RUN mkdir -p /app/.heroku/php /app/.heroku/node /app/.profile.d
WORKDIR /app/user

# Install Apache
RUN curl --silent --location https://robuust-heroku-php.s3.eu-west-1.amazonaws.com/dist-heroku-22-develop/apache-$HTTPD_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Nginx
RUN curl --silent --location https://robuust-heroku-php.s3.eu-west-1.amazonaws.com/dist-heroku-22-develop/nginx-$NGINX_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install PHP
RUN curl --silent --location https://robuust-heroku-php.s3.eu-west-1.amazonaws.com/dist-heroku-22-develop/php-$PHP_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://robuust-heroku-php.s3.eu-west-1.amazonaws.com/dist-heroku-22-develop/extensions/no-debug-non-zts-20210902/redis-$REDIS_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://robuust-heroku-php.s3.eu-west-1.amazonaws.com/dist-heroku-22-develop/extensions/no-debug-non-zts-20210902/imagick-$IMAGICK_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://robuust-heroku-php.s3.eu-west-1.amazonaws.com/dist-heroku-22-develop/extensions/no-debug-non-zts-20210902/pcov-$PCOV_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Composer
RUN curl --silent --location https://robuust-heroku-php.s3.eu-west-1.amazonaws.com/dist-heroku-22-develop/composer-$COMPOSER_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Node
RUN curl --silent --location https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-arm64.tar.gz | tar --strip-components=1 -xz -C /app/.heroku/node

# Select final stage based on TARGETARCH ARG
ARG TARGETARCH
FROM stage-${TARGETARCH} as final
LABEL maintainer="Bob Olde Hampsink <bob@robuust.digital>"

# Internally, we arbitrarily use port 3000
ENV PORT 3000

# Locate our binaries
ENV PATH /app/.heroku/php/bin:/app/.heroku/php/sbin:/app/.heroku/node/bin/:/app/user/node_modules/.bin:/app/user/vendor/bin:/app/user/:$PATH

# Apache Config
RUN curl --silent --location https://raw.githubusercontent.com/heroku/heroku-buildpack-php/master/support/build/_conf/apache2/httpd.conf > /app/.heroku/php/etc/apache2/httpd.conf
# FPM socket permissions workaround when run as root
RUN echo "\n\
Group root\n\
" >> /app/.heroku/php/etc/apache2/httpd.conf

# Nginx Config
RUN curl --silent --location https://raw.githubusercontent.com/heroku/heroku-buildpack-php/master/conf/nginx/main.conf > /app/.heroku/php/etc/nginx/nginx.conf
# FPM socket permissions workaround when run as root
RUN echo "\n\
user nobody root;\n\
" >> /app/.heroku/php/etc/nginx/nginx.conf

# PHP Config
RUN mkdir -p /app/.heroku/php/etc/php/conf.d
RUN curl --silent --location https://raw.githubusercontent.com/heroku/heroku-buildpack-php/master/support/build/_conf/php/7/0/conf.d/000-heroku.ini > /app/.heroku/php/etc/php/php.ini
# Enable all optional exts
RUN echo "\n\
user_ini.cache_ttl = 30 \n\
opcache.enable = 0 \n\
extension=bcmath.so \n\
extension=calendar.so \n\
extension=exif.so \n\
extension=ftp.so \n\
extension=gd.so \n\
extension=gettext.so \n\
extension=intl.so \n\
extension=mbstring.so \n\
extension=pcntl.so \n\
extension=pcov.so \n\
extension=redis.so \n\
extension=imagick.so \n\
extension=shmop.so \n\
extension=soap.so \n\
extension=sodium.so \n\
extension=sqlite3.so \n\
extension=pdo_sqlite.so \n\
extension=xsl.so \n\
" >> /app/.heroku/php/etc/php/php.ini

# Install Yarn
RUN curl --silent --location https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz | tar --strip-components=1 -xz -C /app/.heroku/node

# copy dep files first so Docker caches the install step if they don't change
ONBUILD COPY composer.json composer.lock /app/user/

# run install but without scripts as we don't have the app source yet
ENV COMPOSER_ALLOW_SUPERUSER=1
ONBUILD RUN composer install --prefer-dist --no-scripts --no-progress --no-interaction --no-autoloader

# run npm or yarn install
ONBUILD COPY *package*.json *yarn.lock *.npmrc Dockerfile /app/user/
ONBUILD RUN [ -f yarn.lock ] && yarn install --no-progress --ignore-scripts --network-timeout 1000000 || npm install --no-progress --ignore-scripts --legacy-peer-deps

# rest of app
ONBUILD COPY . /app/user/

# run hooks
ONBUILD RUN cat composer.json | python -c 'import sys,json; sys.exit("post-install-cmd" not in json.load(sys.stdin).get("scripts", {}));' && composer run-script post-install-cmd || true
ONBUILD RUN composer dump-autoload
ONBUILD RUN [ -f yarn.lock ] && yarn install --force --no-progress || npm rebuild --no-progress
