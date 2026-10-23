# Which versions?
ARG PHP_MINOR_VERSION=8.5
ARG PHP_VERSION=${PHP_MINOR_VERSION}.12
ARG PDO_SQLSRV_EXT_VERSION=5.13.3
ARG REDIS_EXT_VERSION=6.3.0
ARG IMAGICK_EXT_VERSION=3.8.1
ARG PCOV_EXT_VERSION=1.0.12
ARG HTTPD_VERSION=2.4.69
ARG NGINX_VERSION=1.30.6
ARG NODE_VERSION=24.22.1
ARG COMPOSER_VERSION=2.10.3

# Inherit from Heroku's stack
FROM --platform=linux/amd64 heroku/heroku:26-build AS stage-amd64
ARG PHP_MINOR_VERSION
ARG PHP_VERSION
ARG PDO_SQLSRV_EXT_VERSION
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
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-amd64-stable/apache-${HTTPD_VERSION}.tar.gz | tar xz -C /app/.heroku/php

# Install Nginx
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-amd64-stable/nginx-${NGINX_VERSION}.tar.gz | tar xz -C /app/.heroku/php

# Install PHP
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-amd64-stable/php-${PHP_VERSION}.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-amd64-stable/ext-redis-${REDIS_EXT_VERSION}_php-${PHP_MINOR_VERSION}.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-amd64-stable/ext-imagick-${IMAGICK_EXT_VERSION}_php-${PHP_MINOR_VERSION}.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-amd64-stable/ext-pcov-${PCOV_EXT_VERSION}_php-${PHP_MINOR_VERSION}.tar.gz | tar xz -C /app/.heroku/php
RUN curl --fail --silent --show-error --location https://robuust-heroku-php.s3.dualstack.eu-west-1.amazonaws.com/dist-heroku-26-develop/extensions/no-debug-non-zts-20250925/pdo_sqlsrv-$PDO_SQLSRV_EXT_VERSION-x86.tar.gz | tar xz -C /app/.heroku/php

# Install Composer
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-amd64-stable/composer-${COMPOSER_VERSION}.tar.gz | tar xz -C /app/.heroku/php

# Install Node
RUN curl --silent --location https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz | tar --strip-components=1 -xz -C /app/.heroku/node

# Inherit from Heroku's stack
FROM --platform=linux/arm64 heroku/heroku:26-build AS stage-arm64
ARG PHP_MINOR_VERSION
ARG PHP_VERSION
ARG PDO_SQLSRV_EXT_VERSION
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
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-arm64-stable/apache-${HTTPD_VERSION}.tar.gz | tar xz -C /app/.heroku/php

# Install Nginx
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-arm64-stable/nginx-${NGINX_VERSION}.tar.gz | tar xz -C /app/.heroku/php

# Install PHP
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-arm64-stable/php-${PHP_VERSION}.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-arm64-stable/ext-redis-${REDIS_EXT_VERSION}_php-${PHP_MINOR_VERSION}.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-arm64-stable/ext-imagick-${IMAGICK_EXT_VERSION}_php-${PHP_MINOR_VERSION}.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-arm64-stable/ext-pcov-${PCOV_EXT_VERSION}_php-${PHP_MINOR_VERSION}.tar.gz | tar xz -C /app/.heroku/php
RUN curl --fail --silent --show-error --location https://robuust-heroku-php.s3.dualstack.eu-west-1.amazonaws.com/dist-heroku-26-develop/extensions/no-debug-non-zts-20250925/pdo_sqlsrv-$PDO_SQLSRV_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Composer
RUN curl --silent --location https://heroku-buildpack-php.s3.dualstack.us-east-1.amazonaws.com/dist-heroku-26-arm64-stable/composer-${COMPOSER_VERSION}.tar.gz | tar xz -C /app/.heroku/php

# Install Node
RUN curl --silent --location https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.gz | tar --strip-components=1 -xz -C /app/.heroku/node

# Select final stage based on TARGETARCH ARG
ARG TARGETARCH
FROM stage-${TARGETARCH} AS final
ARG PHP_MINOR_VERSION
LABEL maintainer="Bob Olde Hampsink <bob@robuust.digital>"

# Internally, we arbitrarily use port 3000
ENV PORT=3000

# The buildpack normally automatically detects the available RAM and CPU cores
# but that doesn't work in Docker, so we set it manually.
# In our Docker environment we have enough memory and cores to set it to 64
ENV WEB_CONCURRENCY=64

# Locate our binaries
ENV PATH=/app/.heroku/php/bin:/app/.heroku/php/sbin:/app/.heroku/node/bin/:/app/user/node_modules/.bin:/app/user/vendor/bin:/app/user:/opt/mssql-tools18/bin:$PATH

# Backport PHP's SimpleXML double-free fix until the next PHP release.
# https://github.com/php/php-src/commit/f9634847258a8c3ed6c12bb79104eba60bb631ea
RUN if [ "$(php-config --version)" = "8.5.12" ]; then \
    apt-get update -qq && apt-get install -qqy libreadline-dev libsqlite3-dev && \
    curl -fsSL https://www.php.net/distributions/php-8.5.12.tar.xz -o /tmp/php.tar.xz && \
    echo '08bc2eba2a588654ade1357174aa646b761556c862dda0678345ee29ed481209  /tmp/php.tar.xz' | sha256sum -c - && \
    tar -xJf /tmp/php.tar.xz -C /tmp && \
    cd /tmp/php-8.5.12 && \
    sed -i 's/zend_hash_release(sxe->properties)/zend_array_release(sxe->properties)/' ext/simplexml/simplexml.c && \
    curl -fsSL https://raw.githubusercontent.com/heroku/heroku-buildpack-php/207f07a27f4644d0cf349febe88219d53695f57d/support/build/patches/php/ignoresigterm.patch -o /tmp/php-fpm.patch && \
    patch -p1 < /tmp/php-fpm.patch && \
    sed -i 's/fpm_trace_type=ptrace/fpm_trace_type=pread/' configure && \
    ./configure $(php-config --configure-options) && \
    make -j$(nproc) sapi/cli/php sapi/fpm/php-fpm sapi/cgi/php-cgi && \
    strip --strip-unneeded sapi/cli/php sapi/fpm/php-fpm sapi/cgi/php-cgi && \
    cp sapi/cli/php sapi/cgi/php-cgi /app/.heroku/php/bin/ && \
    cp sapi/fpm/php-fpm /app/.heroku/php/sbin/ && \
    rm -rf /tmp/php-8.5.12 /tmp/php.tar.xz /tmp/php-fpm.patch; \
    fi

# Install Microsoft ODBC driver, MSSQL tools and unixODBC development headers
RUN curl --fail --silent --show-error --location https://packages.microsoft.com/keys/microsoft-2025.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
  && curl --fail --silent --show-error --location https://packages.microsoft.com/config/ubuntu/26.04/prod.list | tee /etc/apt/sources.list.d/mssql-release.list \
  && apt-get update -qqy \
  && ACCEPT_EULA=Y apt-get -qqy install msodbcsql18 mssql-tools18 unixodbc-dev

# Apache Config
RUN curl --fail --silent --show-error --location https://raw.githubusercontent.com/heroku/heroku-buildpack-php/main/support/build/conf/apache2/httpd.conf > /app/.heroku/php/etc/apache2/httpd.conf
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
# use the defaults for the configured PHP version
RUN curl --fail --silent --show-error --location "https://raw.githubusercontent.com/heroku/heroku-buildpack-php/main/support/build/conf/php/${PHP_MINOR_VERSION%.*}/${PHP_MINOR_VERSION#*.}/conf.d/000-heroku.ini" > /app/.heroku/php/etc/php/php.ini
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
  extension=pdo_sqlsrv.so \n\
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
# share downloaded packages across builds without including the cache in the image
ONBUILD RUN --mount=type=cache,id=heroku-php-composer,target=/var/cache/composer,sharing=shared \
  COMPOSER_CACHE_DIR=/var/cache/composer composer install --prefer-dist --no-scripts --no-progress --no-interaction --no-autoloader

# run yarn install
# share downloaded packages while keeping installed node_modules in the image
ENV YARN_ENABLE_GLOBAL_CACHE=true
ENV YARN_GLOBAL_FOLDER=/var/cache/yarn
ONBUILD COPY *package*.json *yarn.lock .yarn* *.npmrc Dockerfile /app/user/
ONBUILD RUN if [ -f yarn.lock ]; then yarn plugin import https://raw.githubusercontent.com/devoto13/yarn-plugin-engines/main/bundles/%40yarnpkg/plugin-engines.js; fi
ONBUILD RUN --mount=type=cache,id=heroku-php-yarn,target=/var/cache/yarn/cache,sharing=shared \
  if [ -f yarn.lock ]; then yarn install --immutable --mode=skip-build --network-timeout 1000000; fi

# rest of app
ONBUILD COPY . /app/user/

# run composer hooks
ONBUILD RUN cat composer.json | python3 -c 'import sys,json; sys.exit("post-install-cmd" not in json.load(sys.stdin).get("scripts", {}));' && composer run-script post-install-cmd || true
ONBUILD RUN composer dump-autoload

# run yarn hooks
ENV CPPFLAGS="-DPNG_ARM_NEON_OPT=0"
ONBUILD RUN --mount=type=cache,id=heroku-php-yarn,target=/var/cache/yarn/cache,sharing=shared \
  if [ -f yarn.lock ]; then yarn rebuild; fi
