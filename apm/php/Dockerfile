FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and install PHP APM Agent using the working .deb package
RUN cd /tmp \
    && wget https://github.com/elastic/apm-agent-php/releases/download/v1.10.0/apm-agent-php_1.10.0_all.deb \
    && dpkg -i apm-agent-php_1.10.0_all.deb || true \
    && apt-get update && apt-get install -f -y \
    && rm apm-agent-php_1.10.0_all.deb

# Find and configure the extension properly
RUN find /opt -name "elastic_apm.so" -exec cp {} /usr/local/lib/php/extensions/no-debug-non-zts-20220829/ \; || \
    find /usr -name "elastic_apm.so" -exec cp {} /usr/local/lib/php/extensions/no-debug-non-zts-20220829/ \; || \
    echo "Extension file not found, will load from system path"

# Create PHP extension configuration
RUN echo "extension=elastic_apm.so" > /usr/local/etc/php/conf.d/99-elastic-apm.ini \
    && echo "elastic_apm.enabled=1" >> /usr/local/etc/php/conf.d/99-elastic-apm.ini \
    && echo "elastic_apm.service_name=php-app" >> /usr/local/etc/php/conf.d/99-elastic-apm.ini \
    && echo "elastic_apm.log_level=INFO" >> /usr/local/etc/php/conf.d/99-elastic-apm.ini

WORKDIR /var/www/html

EXPOSE 9000