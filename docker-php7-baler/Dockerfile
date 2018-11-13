FROM docker:18.09

MAINTAINER Mingfeng Wang <me.wmf@foxmail.com>

RUN apk --update add wget curl git openssh-client \
 php7 php7-curl php7-openssl php7-json php7-phar php7-dom php7-mbstring && rm /var/cache/apk/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

RUN mkdir -p /var/www

WORKDIR /var/www

CMD ["/bin/sh"]

ENTRYPOINT ["/bin/sh", "-c"]