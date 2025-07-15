FROM docker.io/library/php:8.3-cli

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    libzip-dev \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install opentelemetry

RUN docker-php-ext-enable opentelemetry

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY composer.json ./
RUN composer install --no-dev --no-interaction --prefer-dist

COPY . .

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080", "index.php"]
