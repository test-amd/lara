# Use the official PHP image
FROM php:8.3.7-fpm-alpine

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apk add --no-cache \
    freetype \
    libjpeg-turbo \
    libpng \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    zip \
    libzip-dev \
    imagemagick \
    file

# Install bash
RUN apk update && apk add --no-cache bash

# Setup GD extension
RUN docker-php-ext-configure gd \
    --with-freetype=/usr/include/ \
    --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql zip

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy only Composer files and install dependencies
COPY ./www/composer.lock ./www/composer.json /var/www/html/
RUN composer install --no-scripts --no-autoloader

# Copy application files
COPY ./www /var/www/html/

# Generate autoload files
RUN composer dump-autoload --no-scripts --no-dev --optimize

# Set ownership and permissions for the project directory
RUN adduser -D -u 1000 docker \
    && addgroup docker root \
    && chown -R docker:root /var/www/html \
    && chmod -R 755 /var/www/html

# Set permissions for specific directories
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage/logs/*.log

# Enable core dumps
RUN echo "Set disable_coredump false" >> /etc/sudo.conf
