FROM php:8.2-fpm

# Install system dependencies
RUN apt update && apt install -y \
    unzip \
    curl \
    git \
    nodejs \
    npm \
    libzip-dev \
    nginx \
    openssh-server \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql zip

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configure SSH
RUN mkdir /var/run/sshd
RUN echo 'root:Hello@123' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Configure PHP-FPM to listen on TCP instead of socket
RUN sed -i 's/listen = \/run\/php\/php-fpm.sock/listen = 127.0.0.1:9000/' /usr/local/etc/php-fpm.d/www.conf

# Copy NGINX configuration
COPY nginx.conf /etc/nginx/sites-available/default

# Copy PHP configuration
COPY php.ini /usr/local/etc/php/php.ini

# Set working directory
WORKDIR /var/www

# Copy Laravel application files
COPY laravel/ /var/www/

# Set proper permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader

# Generate Laravel application key if .env doesn't exist
RUN if [ ! -f .env ]; then cp .env.example .env; fi \
    && php artisan key:generate

# Create supervisor configuration
RUN mkdir -p /etc/supervisor/conf.d
COPY <<EOF /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
user=root

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
autostart=true
autorestart=true
stderr_logfile=/var/log/nginx.err.log
stdout_logfile=/var/log/nginx.out.log

[program:php-fpm]
command=/usr/local/sbin/php-fpm -F
autostart=true
autorestart=true
stderr_logfile=/var/log/php-fpm.err.log
stdout_logfile=/var/log/php-fpm.out.log

[program:ssh]
command=/usr/sbin/sshd -D
autostart=true
autorestart=true
stderr_logfile=/var/log/ssh.err.log
stdout_logfile=/var/log/ssh.out.log
EOF

# Expose ports
EXPOSE 8080 22

# Start supervisor
CMD ["/usr/bin/supervisord"]
