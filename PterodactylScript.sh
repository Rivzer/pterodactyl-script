#!/bin/bash
echo "----------------------------------"
echo "[x] Prepare for installation..."
echo "----------------------------------"
sleep 2;
apt update;
sudo apt-get install nano;
service apache2 stop;
echo "----------------------------------"
echo "[x] Welcome by the custom Pterodactyl Installation Script!, Lets start"
echo "----------------------------------"
sleep 5;
echo "----------------------------------"
echo "[x] The installation has started, this takes 10-15 minutes, as soon as the installer asks something, press enter."
echo "----------------------------------"
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
apt update
apt-add-repository universe
apt -y install php8.1 php8.1-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
echo "----------------------------------"
echo "[x] Starting download of panel..."
echo "----------------------------------"
sleep 2;
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
sleep 0.1;
echo "----------------------------------"
echo "[x] Setting up mysql..."
echo "----------------------------------"
sleep 0.5;
echo "[x] Choose a password..."
read MYSQL_PASS;
echo "When asking for a password, just hit enter!"
mysql -u root -p -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASS}';"
mysql -u root -p -e "CREATE DATABASE panel;"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;"
mysql -u root -p -e "FLUSH PRIVILEGES;"
echo "----------------------------------"
echo "[x] Setting up database connection..."
echo "[x] When something is asked than just press ENTER"
echo "----------------------------------"
sleep 1;
cp .env.example .env
composer install --no-dev --optimize-autoloader
curl -o /var/www/pterodactyl/.env https://raw.githubusercontent.com/Rivzer/pterodactyl-script/main/.env
php artisan key:generate --force
sed -i -e "s|DB_PASSWORD=|DB_PASSWORD=${MYSQL_PASS}|g" /var/www/pterodactyl/.env
sleep 0.5;
echo "----------------------------------"
echo "[x] Setting up database setup..."
echo "[x] Just type yes and hit enter"
echo "----------------------------------"
sleep 1;
php artisan migrate --seed --force
echo "----------------------------------"
echo "[x] Creating a user..."
echo "[x] When something is asked than just putin your details"
echo "----------------------------------"
sleep 1;
php artisan p:user:make;
echo "----------------------------------"
echo "[x] Setting up permissions..."
echo "----------------------------------"
sleep 1;
chown -R www-data:www-data /var/www/pterodactyl/*
echo "----------------------------------"
echo "[x] Setting up pteroq service..."
echo "----------------------------------"
sleep 1;
curl -o /etc/systemd/system/pteroq.service https://raw.githubusercontent.com/Rivzer/pterodactyl-script/main/pteroq.service
sudo systemctl enable --now redis-server
sudo systemctl enable --now pteroq.service
echo "----------------------------------"
echo "[x] Setting up web server..."
echo "----------------------------------"
sleep 1;
echo "----------------------------------"
echo "[x] Please giveup your VPS / Server Ip Address"
echo "----------------------------------"
rm /etc/nginx/sites-enabled/default
read FQDN;
curl -o /etc/nginx/sites-available/pterodactyl.conf https://raw.githubusercontent.com/Rivzer/pterodactyl-script/main/pterodactyl.conf
sed -i -e "s/<domain>/${FQDN}/g" /etc/nginx/sites-available/pterodactyl.conf
sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
echo "----------------------------------"
echo "[x] Starting web server..."
echo "----------------------------------"
service apache2 stop
service nginx start
systemctl restart nginx
echo "[x] End of panel installation, the daemon installation will start in 15 seconds... (PRESS CTRL + C IF NOTHING HAS CHANGED IN ANYTHING! OR If you wish yo do no daemon installation!)"
sleep 15;
echo "----------------------------------"
echo "[x] Starting installation daemon"
echo "[x] Docker is being installed ..."
echo "----------------------------------"
cd
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
systemctl enable --now docker
echo "----------------------------------"
echo "[x] Installing node.js"
echo "----------------------------------"
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -;
apt -y install nodejs make gcc g++;
echo "----------------------------------"
echo "[x] Installing Wings (Node)"
echo "----------------------------------"
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
chmod u+x /usr/local/bin/wings
curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/Rivzer/pterodactyl-script/main/wings.service
systemctl enable --now wings
systemctl stop wings
echo "[x] Wings is installed, only a node has to be created on the panel & put in the configuration onto /etc/pterodactyl/config.yml once you have inserted it you can start the node with systemctl start wings"
echo "----------------------------------"
echo "Thank you for using this script!"
echo "Made by Rivzer"
echo "----------------------------------"
