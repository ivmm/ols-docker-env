#FROM debian:jessie-slim
FROM ubuntu:18.04

RUN apt-get update && apt-get install wget curl -y

RUN wget https://openlitespeed.org/preuse/openlitespeed-1.6.5.tgz && \
    tar xzvf openlitespeed-1.6.5.tgz && cd openlitespeed && ./install.sh && rm -rf /openlitespeed

RUN apt-get install mysql-client lsphp73 lsphp73-common lsphp73-mysql lsphp73-opcache \
    lsphp73-curl lsphp73-json lsphp73-imagick lsphp73-redis lsphp73-memcached -y

EXPOSE 7080

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && mv wp-cli.phar /usr/bin/wp && \
	ln -s /usr/local/lsws/lsphp73/bin/php7.3 /usr/bin/php

RUN apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    add-apt-repository ppa:certbot/certbot && \
    apt-get update && \
    apt-get install -y certbot python-certbot-apache

RUN sed 's/0.*.certbot/&  --deploy-hook "\/usr\/local\/lsws\/bin\/lswsctrl restart"/g' /etc/cron.d/certbot

RUN rm -rf /usr/local/lsws/conf
ADD conf /usr/local/lsws/conf
RUN chown 999:999 /usr/local/lsws/conf -R
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /var/www/vhosts/
CMD ["/usr/local/lsws/bin/lswsctrl","start"]