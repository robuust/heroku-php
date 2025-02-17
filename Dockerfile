# Which versions?
ARG PHP_VERSION=8.4.4
ARG REDIS_EXT_VERSION=6.1.0
ARG IMAGICK_EXT_VERSION=3.7.0
ARG PCOV_EXT_VERSION=1.0.12
ARG HTTPD_VERSION=2.4.63
ARG NGINX_VERSION=1.26.3
ARG NODE_VERSION=22.14.0
ARG COMPOSER_VERSION=2.8.5

# Inherit from Heroku's stack
FROM --platform=linux/amd64 heroku/heroku:24-build AS stage-amd64
ARG PHP_VERSION
ARG REDIS_EXT_VERSION
ARG IMAGICK_EXT_VERSION
ARG PCOV_EXT_VERSION
ARG HTTPD_VERSION
ARG NGINX_VERSION
ARG NODE_VERSION
ARG COMPOSER_VERSION

# Create some needed directories
USER root
RUN mkdir -p /app/.heroku/php /app/.heroku/node /app/.profile.d
WORKDIR /app/user

# Install Apache
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-amd64-stable/apache-$HTTPD_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Nginx
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-amd64-stable/nginx-$NGINX_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install PHP
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-amd64-stable/php-$PHP_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-amd64-stable/extensions/no-debug-non-zts-20240924/redis-$REDIS_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-amd64-stable/extensions/no-debug-non-zts-20240924/imagick-$IMAGICK_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-amd64-stable/extensions/no-debug-non-zts-20240924/pcov-$PCOV_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Composer
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-amd64-stable/composer-$COMPOSER_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Node
RUN curl --silent --location https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz | tar --strip-components=1 -xz -C /app/.heroku/node

# Inherit from Heroku's stack
FROM --platform=linux/arm64 heroku/heroku:24-build AS stage-arm64
ARG PHP_VERSION
ARG REDIS_EXT_VERSION
ARG IMAGICK_EXT_VERSION
ARG PCOV_EXT_VERSION
ARG HTTPD_VERSION
ARG NGINX_VERSION
ARG NODE_VERSION
ARG COMPOSER_VERSION

# Create some needed directories
USER root
RUN mkdir -p /app/.heroku/php /app/.heroku/node /app/.profile.d
WORKDIR /app/user

# Install Apache
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-arm64-stable/apache-$HTTPD_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Nginx
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-arm64-stable/nginx-$NGINX_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install PHP
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-arm64-stable/php-$PHP_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-arm64-stable/extensions/no-debug-non-zts-20240924/redis-$REDIS_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-arm64-stable/extensions/no-debug-non-zts-20240924/imagick-$IMAGICK_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-arm64-stable/extensions/no-debug-non-zts-20240924/pcov-$PCOV_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Composer
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-24-arm64-stable/composer-$COMPOSER_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Node
RUN curl --silent --location https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-arm64.tar.gz | tar --strip-components=1 -xz -C /app/.heroku/node

# Select final stage based on TARGETARCH ARG
ARG TARGETARCH
FROM stage-${TARGETARCH} AS final
LABEL maintainer="Bob Olde Hampsink <bob@robuust.digital>"

# Internally, we arbitrarily use port 3000
ENV PORT=3000

# Locate our binaries
ENV PATH=/app/.heroku/php/bin:/app/.heroku/php/sbin:/app/.heroku/node/bin/:/app/user/node_modules/.bin:/app/user/vendor/bin:/app/user/:$PATH

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

# Enable Corepack
ENV COREPACK_ENABLE_AUTO_PIN=0
RUN corepack enable --install-directory /app/.heroku/node/bin/

# copy dep files first so Docker caches the install step if they don't change
ONBUILD COPY composer.json composer.lock /app/user/

# run install but without scripts as we don't have the app source yet
ENV COMPOSER_ALLOW_SUPERUSER=1
ONBUILD RUN composer install --prefer-dist --no-scripts --no-progress --no-interaction --no-autoloader

# run yarn install
ONBUILD COPY *package*.json *yarn.lock .yarn* *.npmrc Dockerfile /app/user/
ONBUILD RUN if [ -f yarn.lock ]; then yarn plugin import https://raw.githubusercontent.com/devoto13/yarn-plugin-engines/main/bundles/%40yarnpkg/plugin-engines.js; fi
ONBUILD RUN if [ -f yarn.lock ]; then yarn install --mode=skip-build --network-timeout 1000000; fi

# rest of app
ONBUILD COPY . /app/user/

# run composer hooks
ONBUILD RUN cat composer.json | python3 -c 'import sys,json; sys.exit("post-install-cmd" not in json.load(sys.stdin).get("scripts", {}));' && composer run-script post-install-cmd || true
ONBUILD RUN composer dump-autoload

# run yarn hooks
ENV CPPFLAGS="-DPNG_ARM_NEON_OPT=0"
ONBUILD RUN if [ -f yarn.lock ]; then yarn rebuild; fi
