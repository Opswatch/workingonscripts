
#!/bin/bash


echo "Powered by deployanat0r"
# Update
echo "===Updating ubuntu==="
sudo apt update && sudo apt upgrade -y
echo "===Updating Complete==="

# Install Nginx
echo "===Installing Nginx==="
apt-get update
apt install nginx -y
chown www-data /usr/share/nginx/html -R
rm /etc/nginx/sites-enabled/default

echo "===Done installing Nginx==="

# Install Mysql

echo "===Installing Mysql==="
apt install mysql-server -y 
#service mysql stop # Stop the MySQL if is running.
service mysql start
mysql_secure_installation
echo "===Done Installing Mysql===" 

# Install needed modules for PHP install PHP
echo "===Installing PHP Modules==="
apt install php7.2-cli php7.2-fpm php7.2-mysql php7.2-json php7.2-opcache php7.2-mbstring php7.2-xml php7.2-gd php7.2-curl -y
systemctl start php7.2-fpm
echo "===Done Installing PHP Modules==="

# Install Composer (PHP dependencies manager)
## First install php-cli, unzip, git, curl, php-mbstring
echo "===Installing Composer==="
apt install curl git unzip -y
## Downloading and installing Composer
cd ~
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
echo "===Done Installing Composer==="

echo "===Starting environment configuration and Drupal installation==="
# Start Nginx
systemctl start nginx.service
systemctl enable nginx.service

# Start MariaDB
systemctl start mysql.service
systemctl enable mysql.service

# Configure DB
 mysqladmin create drupal
 mysql -e "CREATE USER 'drupaluser' IDENTIFIED BY 'changeme';"
 mysql -e "GRANT ALL PRIVILEGES ON drupal.* TO 'drupaluser' WITH GRANT OPTION;"

# Add Nginx virtual host

echo "server {
  listen 80;
  server_name 172.16.0.152;
  root /var/www/drupal;
  index index.php index.html index.htm;

  error_page 404 /404.html;
  error_page 500 502 503 504 /50x.html;

  location = /50x.html {
    root /var/www/drupal;
  }

  location ~ \..*/.*\.php$ {
    return 403;
  }

  # Block access to hidden directories
  location ~ (^|/)\. {
    return 403;
  }

  location ~ ^/sites/.*/private/ {
    return 403;
  }

  # No php is touched for static content
  location / {
    try_files $uri @rewrite;
  }

  # Clean URLs
  location @rewrite {
    rewrite ^ /index.php;
  }

  # Image styles
  location ~ ^/sites/.*/files/styles/ {
    try_files $uri @rewrite;
  }

  location = /favicon.ico {
    log_not_found off;
    access_log off;
  }

  location = /robots.txt {
    allow all;
    log_not_found off;
    access_log off;
  }

  location ~ \.php$ {
    try_files $uri =404;
    fastcgi_pass unix:/run/php/php7.2-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    include fastcgi_params;
  }
}" >> /var/www/drupal

ln -s /var/www/drupal /etc/nginx/conf.d/drupal.conf

systemctl reload nginx;

# Download drupal
sudo composer create-project drupal-composer/drupal-project:8.x-dev /var/www/drupal --stability dev --no-interaction

# Install Drupal files into Webserver's root directory /var/www/html and change the file ownership to www-data
cd /var/www/drupal
sudo vendor/bin/drush site-install --db-url=mysql://drupaluser:changeme@localhost/drupal -y
chown -R www-data:www-data /var/www/drupal -R

echo "Server and Drupal installation completed - please finish configuring Drupal"