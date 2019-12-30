FROM ubuntu:xenial
LABEL maintainer="mehdi.bounya@gmail.com"

# Prepare system
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends apt-utils systemd \
	vim wget net-tools git unzip curl iputils-ping telnet dnsutils \
	software-properties-common apt-transport-https make libgnutls28-dev libcurl4-gnutls-dev; \
	LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php

# Install needed packages
RUN echo mysql-server mysql-server/root_password password root | debconf-set-selections;\
	echo mysql-server mysql-server/root_password_again password root | debconf-set-selections;\
	apt-get update && apt-get install -y mysql-server mysql-client libmysqlclient-dev nginx \
	php7.4 php7.4-fpm php7.4-cli php7.4-mysql php7.4-curl php7.4-xml php7.4-mbstring php7.4-xdebug \
	php-dev php-pear

# Copy config files
COPY ./conf/nginx /etc/nginx/sites-available/default
COPY ./conf/php.ini /etc/php/7.4/cli/php.ini
COPY conf/xdebug.ini /usr/local/etc/php/conf.d/xdebug-dev.ini

# Start services
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf && \
	find /var/lib/mysql -type f -exec touch {} \; && service mysql start && \
	service php7.4-fpm start && mkdir /etc/nginx/conf && touch /etc/nginx/conf/env_vars && service nginx restart && \
	mysql -uroot -proot mysql -e "UPDATE user SET host='%' WHERE user='root'; FLUSH privileges;"

# Install extra tools
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php && \
	php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
	wget -O phpunit https://phar.phpunit.de/phpunit-8.phar && \
	chmod +x phpunit && \
	mv phpunit /usr/local/bin/phpunit && \
	wget https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64.deb && \
	dpkg -i dumb-init_*.deb

# Expose Ports
EXPOSE 443 80 3306

# Prepare image
COPY ./scripts/start.sh start.sh
RUN chmod a+x start.sh && rm -rf /var/www/html && mkdir -p /app/public && ln -s /app/public /var/www/html

WORKDIR /app

CMD ["dumb-init", "--", "/start.sh"]
