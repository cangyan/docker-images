FROM ubuntu:16.04

MAINTAINER Mingfeng Wang <me.wmf@foxmail.com>

RUN mkdir -p /var/www && \
    mkdir -p /run/php

RUN apt-get update && \
    apt-get install -y dialog apt-utils software-properties-common python-software-properties

RUN apt-get install -y openssl wget

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

RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.1/cli/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/display_errors = Off/display_errors = On/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/upload_max_filesize = .*/upload_max_filesize = 10M/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/post_max_size = .*/post_max_size = 12M/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini

RUN sed -i -e "s/pid =.*/pid = \/var\/run\/php7.1-fpm.pid/" /etc/php/7.1/fpm/php-fpm.conf
RUN sed -i -e "s/error_log =.*/error_log = \/proc\/self\/fd\/2/" /etc/php/7.1/fpm/php-fpm.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf
RUN sed -i "s/listen = .*/listen = 9000/" /etc/php/7.1/fpm/pool.d/www.conf
RUN sed -i "s/;catch_workers_output = .*/catch_workers_output = yes/" /etc/php/7.1/fpm/pool.d/www.conf

WORKDIR /var/www

EXPOSE 9000

CMD ["/usr/sbin/php-fpm7.1", "-F"]

