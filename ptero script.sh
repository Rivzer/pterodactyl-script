#!/bin/bash
apt update -y
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
apt update
apt-add-repository universe
apt -y install php8.1 php8.1-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
read dbpass
mysql -u root -p
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$dbpass';
CREATE DATABASE panel;
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
exit
cp .env.example .env
composer install --no-dev --optimize-autoloader
php artisan key:generate --force
php artisan p:environment:setup
php artisan p:environment:database
php artisan migrate --seed --force
php artisan p:user:make
chown -R www-data:www-data /var/www/pterodactyl/*