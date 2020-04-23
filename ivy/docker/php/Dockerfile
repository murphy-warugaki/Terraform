FROM php:7.2.10-fpm

ARG UID=991
ARG UNAME=www
ARG GID=991
ARG GNAME=www

ENV WORKDIR=/var/www/html
WORKDIR $WORKDIR

COPY ./docker/php/php.ini /usr/local/etc/php
COPY ./docker/php/laravel/Ivy/composer.json ${WORKDIR}/

RUN apt-get -y update \
    && apt-get install -y git
RUN git clone https://github.com/phpredis/phpredis.git /usr/src/php/ext/redis

RUN set -x \
    %% apt-get -y update \
    && apt-get install -y zlib1g-dev \
    && apt-get install -y vim \
    && apt-get install -y curl \
    && apt-get install -y libicu-dev \
    && apt-get install -y libpq-dev \
    && docker-php-ext-install pdo_mysql zip sockets redis \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer install --no-autoloader --no-progress --no-dev

COPY ./docker/php/laravel/Ivy/ .

RUN set -x \
    && composer install --no-progress --no-dev \
    && php artisan config:clear \
    && groupadd ${GNAME} -g ${GID} \
    && useradd -g ${GID} -u ${UID} ${UNAME} \
    && chown -R ${UNAME}:${GNAME} ${WORKDIR} \
    && mv /root/.composer /home/${UNAME}/ \
    && chown -R ${UNAME}:${GNAME} /home/${UNAME}

# vue setting
RUN apt-get install -y gnupg \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get install -y nodejs

USER ${UNAME}
