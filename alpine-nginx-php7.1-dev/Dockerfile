FROM alpine:3.7

MAINTAINER Mingfeng Wang <me.wmf@foxmail.com>

# Install packages
RUN apk --no-cache add php7 php7-session php7-memcached php7-redis php7-fpm php7-cli\
	#php and ext
		php7-mcrypt \
		php7-openssl \
		php7-curl \
		php7-json \
		php7-dom \
		php7-bcmath \
		php7-gd \
		php7-pdo \
		php7-pdo_mysql \
		php7-pdo_sqlite \
		php7-pdo_odbc \
		php7-pdo_dblib \
		php7-gettext \
		php7-iconv \
		php7-ctype \
		php7-phar \
		php7-mbstring \
		php7-xml \
		php7-tokenizer \
		php7-xmlwriter \
		nginx supervisor curl

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/zzz_custom.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup the Composer installer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

RUN php /tmp/composer-setup.php

RUN mv composer.phar /usr/local/bin/composer

# Add application
RUN mkdir -p /var/www
WORKDIR /var/www

EXPOSE 80 443
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]