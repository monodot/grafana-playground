FROM docker.io/serversideup/php:8.4-fpm-nginx-alpine-v3.5.1

WORKDIR /var/www/html

USER root

RUN apk add --no-cache autoconf build-base
RUN pecl install opentelemetry
RUN docker-php-ext-enable opentelemetry

USER www-data

COPY composer.json ./
RUN composer install --no-dev --no-interaction --prefer-dist

COPY src src
COPY public public
