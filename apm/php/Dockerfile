FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and install PHP APM Agent v1.15.1 based on architecture
RUN cd /tmp \
    && ARCH=$(dpkg --print-architecture) \
    && echo "Detected architecture: $ARCH" \
    && if [ "$ARCH" = "amd64" ]; then \
         wget https://github.com/elastic/apm-agent-php/releases/download/v1.15.1/apm-agent-php_1.15.1_amd64.deb; \
       elif [ "$ARCH" = "arm64" ]; then \
         wget https://github.com/elastic/apm-agent-php/releases/download/v1.15.1/apm-agent-php_1.15.1_arm64.deb; \
       else \
         echo "Unsupported architecture: $ARCH" && exit 1; \
       fi \
    && dpkg -i apm-agent-php_1.15.1_*.deb || true \
    && apt-get update && apt-get install -f -y \
    && rm apm-agent-php_1.15.1_*.deb

# Find and configure the extension properly
RUN find /opt -name "elastic_apm.so" -exec cp {} /usr/local/lib/php/extensions/no-debug-non-zts-20220829/ \; || \
    find /usr -name "elastic_apm.so" -exec cp {} /usr/local/lib/php/extensions/no-debug-non-zts-20220829/ \; || \
    echo "Extension file not found, will load from system path"

# Create PHP extension configuration with full path
RUN echo "extension=/opt/elastic/apm-agent-php/lib/elastic_apm-20220829.so" > /usr/local/etc/php/conf.d/99-elastic-apm.ini || \
    echo "extension=elastic_apm.so" > /usr/local/etc/php/conf.d/99-elastic-apm.ini
RUN echo "elastic_apm.enabled=1" >> /usr/local/etc/php/conf.d/99-elastic-apm.ini \
    && echo "elastic_apm.service_name=php-app" >> /usr/local/etc/php/conf.d/99-elastic-apm.ini \
    && echo "elastic_apm.log_level=INFO" >> /usr/local/etc/php/conf.d/99-elastic-apm.ini

# Configure PHP-FPM logging with correct directives
RUN echo "[global]" > /usr/local/etc/php-fpm.d/logging.conf \
    && echo "error_log = /var/log/php/php-fpm.log" >> /usr/local/etc/php-fpm.d/logging.conf \
    && echo "log_level = notice" >> /usr/local/etc/php-fpm.d/logging.conf \
    && echo "" >> /usr/local/etc/php-fpm.d/logging.conf \
    && echo "[www]" >> /usr/local/etc/php-fpm.d/logging.conf \
    && echo "catch_workers_output = yes" >> /usr/local/etc/php-fpm.d/logging.conf \
    && echo "decorate_workers_output = no" >> /usr/local/etc/php-fpm.d/logging.conf

# Configure PHP error logging
RUN echo "log_errors = On" >> /usr/local/etc/php/conf.d/99-logging.ini \
    && echo "error_log = /var/log/php/error.log" >> /usr/local/etc/php/conf.d/99-logging.ini \
    && mkdir -p /var/log/php

WORKDIR /var/www/html

EXPOSE 9000