FROM php:7-fpm

MAINTAINER Mingfeng Wang <me.wmf@foxmail.com>

# Setup the Composer installer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

RUN php /tmp/composer-setup.php

RUN mv composer.phar /usr/local/bin/composer

RUN apt-get update && apt-get install -y git && docker-php-ext-install pdo_mysql

WORKDIR /var/www
