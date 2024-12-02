##############################################
# Stage 1: Install node dependencies and run gulp
##############################################

FROM arm64v8/node:11 as npm
WORKDIR /app

COPY package.json /app
COPY package-lock.json /app
RUN npm install

COPY resources /app/resources
COPY gulpfile.js /app
RUN npm run gulp

##############################################
# Stage 2: Composer, nginx and fpm
##############################################

FROM dwchiang/nginx-php-fpm:7.3.33-fpm-bullseye-nginx-1.24.0
WORKDIR /var/www/html

# Contains laravel echo server proxy configuration
COPY /nginx.conf /etc/nginx/conf.d/default.conf

# install git
RUN apt-get install -y \
    git \
    curl \
    unzip \
    libzip-dev

RUN docker-php-ext-install zip

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=1.10.22
RUN chmod +x /usr/local/bin/composer
RUN mkdir -p /var/www/.composer && chown -R www-data:www-data /var/www/.composer

USER www-data

ADD --chown=www-data:www-data /composer.json /var/www/html
ADD --chown=www-data:www-data /composer.lock /var/www/html

RUN composer global require hirak/prestissimo \
    && composer install --no-interaction --no-autoloader --no-dev --prefer-dist --no-scripts \
    && rm -rf /home/www-data/.composer/cache

ADD --chown=www-data:www-data /storage /var/www/html/storage
ADD --chown=www-data:www-data /bootstrap /var/www/html/bootstrap
ADD --chown=www-data:www-data /public /var/www/html/public
ADD --chown=www-data:www-data /artisan /var/www/html
ADD --chown=www-data:www-data /database /var/www/html/database
ADD --chown=www-data:www-data /config /var/www/html/config
ADD --chown=www-data:www-data /app /var/www/html/app

RUN composer dump-autoload --optimize --no-dev \
    && touch /var/www/html/database/database.sqlite \
    && php artisan optimize \
    && php artisan migrate

ADD --chown=www-data:www-data /resources /var/www/html/resources
COPY --chown=www-data:www-data --from=npm /app/public/css /var/www/html/public/css
COPY --chown=www-data:www-data --from=npm /app/public/js /var/www/html/public/js

USER root
