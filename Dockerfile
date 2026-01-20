FROM php:8.3-cli

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /app

# Copy project files
COPY . /app

# Install dependencies
RUN composer install --no-interaction --optimize-autoloader --verbose || \
    (echo "Composer install failed!" && exit 1)

# Expose port
EXPOSE 8000

# Start Symfony server
CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]
