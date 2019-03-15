FROM alpine:3.7

MAINTAINER Mingfeng Wang <me.wmf@foxmail.com>

# Environments
ENV PORT=9000 \
	TIMEZONE=UTC \
	MAX_UPLOAD=10M \
	DISPLAY_ERROR=1 \
	STARTUP_ERROR=1 \
	ASSERTIONS=0 FPM_USER=www FPM_CONF=/etc/php7/php-fpm.conf FPM_PATH='/etc/php7/fpm.d/' \
	PHP_INI="/etc/php7/php.ini"

# install PHP
RUN	PHP_CONF="/etc/php7/conf.d" \
    && apk add --no-cache git curl php7 php7-session php7-memcached php7-redis php7-fpm php7-cli\
		libmemcached-libs \
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
		php7-pcntl \
		php7-phar \
		php7-mbstring \
		php7-xml \
		php7-tokenizer \
	# Set php.ini
	&& ADD_EXT(){ echo -e "extension = ${1}.so; \n${2}" > "$PHP_CONF/${1}.ini"; } \
	#ADD_EXT \
	&& ADD_EXT yaf "[yaf]\nyaf.environ = dev" \
	&& ln -s /usr/sbin/php-fpm7 /usr/bin/php-fpm \
	&& rm -rf /var/cache/apk/* \
		/var/tmp/* \
		/tmp/* \
		/etc/ssl/certs/*.pem \
		/etc/ssl/certs/*.0 \
		/usr/share/ca-certificates/mozilla/* \
		/usr/share/man/* \
		/usr/include/*

#COPY build extensions
COPY ./modules/*.so /usr/lib/php7/modules/
COPY entry.sh /entry.sh

# Setup the Composer installer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

RUN php /tmp/composer-setup.php

RUN mv composer.phar /usr/local/bin/composer

WORKDIR /var/www

EXPOSE $PORT

ENTRYPOINT [ "/entry.sh" ]

#CMD
CMD ["/usr/bin/php-fpm","-F"]