FROM ubuntu:xenial
LABEL maintainer="mehdi.bounya@gmail.com"

# Prepare system
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils systemd

# Basic tools
RUN apt-get install -y vim wget net-tools git unzip curl iputils-ping telnet dnsutils \
software-properties-common apt-transport-https

# Nginx
RUN apt-get install -y nginx
COPY ./conf/nginx /etc/nginx/sites-available/default

# Install MySQL
RUN echo mysql-server mysql-server/root_password password root | debconf-set-selections;\
	echo mysql-server mysql-server/root_password_again password root | debconf-set-selections;\
	apt-get install -y mysql-server mysql-client libmysqlclient-dev

# Start MySQL
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
RUN find /var/lib/mysql -type f -exec touch {} \; && service mysql start

## Allow MySQL connection from any host
RUN find /var/lib/mysql -type f -exec touch {} \; && service mysql start && service mysql start && mysql -uroot -proot mysql  -e "update user set host='%' where user='root' and host='localhost';flush privileges; CREATE DATABASE test;"

# Install PHP7.3
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
apt-get install -y php7.3 php7.3-fpm php7.3-cli php7.3-mysql php7.3-curl php7.3-xml php7.3-mbstring
COPY ./conf/php.ini /etc/php/7.3/cli/php.ini

# Start webserver
RUN service php7.3-fpm start
RUN service nginx restart

# Install composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN composer

# Install PHPUnit
RUN wget -O phpunit https://phar.phpunit.de/phpunit-8.phar
RUN chmod +x phpunit
RUN mv phpunit /usr/local/bin/phpunit
RUN phpunit --version

# Install xdebug (code-coverage)
RUN apt-get install php7.3-xdebug
COPY conf/xdebug.ini /usr/local/etc/php/conf.d/xdebug-dev.ini

# Install dumb-init
RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64.deb
RUN dpkg -i dumb-init_*.deb

# Expose Ports
EXPOSE 443
EXPOSE 80
EXPOSE 3306

# Copy start script
COPY ./scripts/start.sh start.sh
RUN chmod a+x start.sh

# Prepare home folder
RUN rm -rf /var/www/html && mkdir -p /app/public && ln -s /app/public /var/www/html

WORKDIR /app

CMD ["dumb-init", "--", "/start.sh"]
