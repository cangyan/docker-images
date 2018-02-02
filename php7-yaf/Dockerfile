FROM ubuntu:16.04

MAINTAINER Mingfeng Wang <me.wmf@foxmail.com>

RUN mkdir -p /var/www && \
    mkdir -p /run/php

RUN apt-get update && \
    apt-get install -y dialog apt-utils

RUN apt-get install -y software-properties-common python-software-properties openssl wget

RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y php7.1-dev php7.1-cli php7.1-fpm php7.1-common php7.1-curl php7.1-json php7.1-gd php7.1-mysql php7.1-sqlite3 php7.1-soap php7.1-xml php7.1-zip php7.1-gettext php7.1-mbstring php7.1-mcrypt php7.1-intl php7.1-imap imagemagick php-imagick graphicsmagick && \
    apt-get autoremove -y

# yaf ext
RUN mkdir -p /tmp/yaf && \
    cd /tmp/yaf && \
    wget https://github.com/laruence/yaf/archive/yaf-3.0.6.tar.gz && \
    tar -zxvf yaf-3.0.6.tar.gz && \
    cd yaf-yaf-3.0.6 && \
    phpize && \
    ./configure && \
    make && make install && \
    echo "[yaf]" >> /etc/php/7.1/cli/php.ini && \
    echo "extension=yaf.so" >> /etc/php/7.1/cli/php.ini && \
    echo "[yaf]" >> /etc/php/7.1/fpm/php.ini && \
    echo "extension=yaf.so" >> /etc/php/7.1/fpm/php.ini

# redis ext
RUN mkdir -p /tmp/redis && \
    cd /tmp/redis && \
    wget https://github.com/phpredis/phpredis/archive/3.1.6.tar.gz && \
    tar -zxvf 3.1.6.tar.gz && \
    cd phpredis-3.1.6 && \
    phpize && \
    ./configure && \
    make && make install && \
    echo "[redis]" >> /etc/php/7.1/cli/php.ini && \
    echo "extension=redis.so" >> /etc/php/7.1/cli/php.ini && \
    echo "[redis]" >> /etc/php/7.1/fpm/php.ini && \
    echo "extension=redis.so" >> /etc/php/7.1/fpm/php.ini

RUN touch /tmp/stdout
CMD sh -c "php-fpm7.1 | tail -f /tmp/stdout"

WORKDIR /var/www

EXPOSE 9000
