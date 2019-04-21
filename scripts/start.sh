#!/bin/bash

# Import environment variables
echo "Passing environment variables to Nginx"
echo -n "" > /etc/nginx/conf/env_vars
while read -r line; do
	echo "Line: $line"
	NAME=$(echo $line | cut -d "=" -f 1)
	VALUE=$(echo $line | cut -d "=" -f 2-)
	echo "fastcgi_param $NAME \"$VALUE\";" >> /etc/nginx/conf/env_vars
done <<< "$(env)"

# Start mysql
echo "Starting mysql..."
find /var/lib/mysql -type f -exec touch {} \; && service mysql start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start mysql: $status"
  exit $status
fi
echo "Done."

# Start PHP-fpm
echo "Starting PHP-fpm..."
service php7.3-fpm start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start PHP-fpm: $status"
  exit $status
fi
echo "Done."

# Start nginx
echo "Starting nginx .... "
nginx -g "daemon off;"
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start nginx: $status"
  exit $status
fi
echo "Done."
echo "You can now access your web application."
