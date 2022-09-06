# Inherit from Heroku's stack
FROM heroku/heroku:20
LABEL maintainer="Bob Olde Hampsink <bob@robuust.digital>"

# Internally, we arbitrarily use port 3000
ENV PORT 3000

# Which versions?
ENV PHP_VERSION 8.1.10
ENV PDO_SQLSRV_EXT_VERSION 5.10.1_php-8.1
ENV REDIS_EXT_VERSION 5.3.7
ENV IMAGICK_EXT_VERSION 3.7.0
ENV PCOV_EXT_VERSION 1.0.11
ENV HTTPD_VERSION 2.4.54
ENV NGINX_VERSION 1.22.0
ENV NODE_VERSION 16.17.0
ENV COMPOSER_VERSION 2.4.1
ENV YARN_VERSION 1.22.19

# Create some needed directories
RUN mkdir -p /app/.heroku/php /app/.heroku/node /app/.profile.d
WORKDIR /app/user

# Locate our binaries
ENV PATH /app/.heroku/php/bin:/app/.heroku/php/sbin:/app/.heroku/node/bin/:/app/user/node_modules/.bin:/app/user/vendor/bin:/app/user:/opt/mssql-tools/bin:$PATH

# Install Microsoft ODBC driver, MSSQL tools and unixODBC development headers
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
 && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
 && apt-get update -qqy \
 && ACCEPT_EULA=Y apt-get -qqy install msodbcsql17 mssql-tools unixodbc-dev

# Install Apache
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-20-stable/apache-$HTTPD_VERSION.tar.gz | tar xz -C /app/.heroku/php
# Config
RUN curl --silent --location https://raw.githubusercontent.com/heroku/heroku-buildpack-php/master/support/build/_conf/apache2/httpd.conf > /app/.heroku/php/etc/apache2/httpd.conf
# FPM socket permissions workaround when run as root
RUN echo "\n\
Group root\n\
" >> /app/.heroku/php/etc/apache2/httpd.conf

# Install Nginx
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-20-stable/nginx-$NGINX_VERSION.tar.gz | tar xz -C /app/.heroku/php
# Config
RUN curl --silent --location https://raw.githubusercontent.com/heroku/heroku-buildpack-php/master/conf/nginx/main.conf > /app/.heroku/php/etc/nginx/nginx.conf
# FPM socket permissions workaround when run as root
RUN echo "\n\
user nobody root;\n\
" >> /app/.heroku/php/etc/nginx/nginx.conf

# Install PHP
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-20-stable/php-$PHP_VERSION.tar.gz | tar xz -C /app/.heroku/php
# Config
RUN mkdir -p /app/.heroku/php/etc/php/conf.d
RUN curl --silent --location https://raw.githubusercontent.com/heroku/heroku-buildpack-php/master/support/build/_conf/php/7/0/conf.d/000-heroku.ini > /app/.heroku/php/etc/php/php.ini
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-20-stable/extensions/no-debug-non-zts-20210902/redis-$REDIS_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-20-stable/extensions/no-debug-non-zts-20210902/imagick-$IMAGICK_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-20-stable/extensions/no-debug-non-zts-20210902/pcov-$PCOV_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php
RUN curl --silent --location https://github.com/robuust/heroku-php/raw/pdo_sqlsrv/packages/ext-pdo_sqlsrv-$PDO_SQLSRV_EXT_VERSION.tar.gz | tar xz -C /app/.heroku/php
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

# Install Composer
RUN curl --silent --location https://lang-php.s3.us-east-1.amazonaws.com/dist-heroku-20-stable/composer-$COMPOSER_VERSION.tar.gz | tar xz -C /app/.heroku/php

# Install Node
RUN curl --silent --location https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz | tar --strip-components=1 -xz -C /app/.heroku/node

# Install Yarn
RUN curl --silent --location https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz | tar --strip-components=1 -xz -C /app/.heroku/node

# Install Chrome WebDriver
RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` \
 && mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION \
 && curl -sS -o /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip \
 && unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver-$CHROMEDRIVER_VERSION \
 && rm /tmp/chromedriver_linux64.zip \
 && chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver \
 && ln -fs /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver /usr/local/bin/chromedriver

# Install Google Chrome
ENV DEBIAN_FRONTEND noninteractive
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
 && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update -qqy \
 && apt-get -qqy install google-chrome-stable \
 && rm /etc/apt/sources.list.d/google-chrome.list \
 && rm -rf /var/lib/apt/lists/*

# copy dep files first so Docker caches the install step if they don't change
ONBUILD COPY composer.json composer.lock /app/user/

# run install but without scripts as we don't have the app source yet
ONBUILD RUN composer install --prefer-dist --no-scripts --no-progress --no-interaction --no-autoloader

# run npm or yarn install
ONBUILD COPY *package*.json *yarn.lock *.npmrc Dockerfile /app/user/
ONBUILD RUN [ -f yarn.lock ] && yarn install --no-progress --ignore-scripts || npm install --no-progress --ignore-scripts

# rest of app
ONBUILD COPY . /app/user/

# run hooks
ONBUILD RUN cat composer.json | python -c 'import sys,json; sys.exit("post-install-cmd" not in json.load(sys.stdin).get("scripts", {}));' && composer run-script post-install-cmd || true
ONBUILD RUN composer dump-autoload
ONBUILD RUN [ -f yarn.lock ] && yarn install --force --no-progress || npm rebuild --no-progress
