#!/bin/bash
# Script d'installation de GLPI
# Par Logan Le Paire
# Version 1
---------------------------------------------------------------------------


sudo apt-get update && sudo apt-get upgrade -y

sudo apt-get install apache2 php mariadb-server
sudo apt-get install php-xml php-common php-json php-mysql php-mbstring php-curl php-gd php-intl php-zip php-bz2 php-imap php-apcu
sudo apt-get install php-ldap

sudo mysql_secure_installation # (n,y,y,y,y,y)
namedb=$(whiptail --inputbox "Pour changer le nom de la Base de Donnée, saisissez le nouveau nom" 8 39 db578_glpi --title "Nom de la Base de Donnée" 3>&1 1>&2 2>&3)
userdb=$(whiptail --inputbox "Pour changer le nom d'utilisateur de la Base de Donnée, saisissez le nouveau nom" 8 39 glpidb_adm --title "Nom de l'utilisateur de la Base de Donnée" 3>&1 1>&2 2>&3)
mdpdb=$(whiptail --inputbox "Pour changer le mot de passe de la Base de Donnée, saisissez le nouveau mot de passe" 8 39 MotDePasseRobuste --title "Mot de passe de la Base de Donnée" 3>&1 1>&2 2>&3)
sudo mysql -u root -p


CREATE DATABASE $namedb;
GRANT ALL PRIVILEGES ON $namedb.* TO $userdb@localhost IDENTIFIED BY "$mdpdb";
FLUSH PRIVILEGES;
EXIT

cd /tmp
wget https://github.com/glpi-project/glpi/releases/download/10.0.14/glpi-10.0.14.tgz
sudo tar -xzvf glpi-10.0.14.tgz -C /var/www/
sudo chown www-data /var/www/glpi/ -R

sudo mkdir /etc/glpi
sudo chown www-data /etc/glpi/

sudo mv /var/www/glpi/config /etc/glpi

sudo mkdir /var/lib/glpi
sudo chown www-data /var/lib/glpi/

sudo mv /var/www/glpi/files /var/lib/glpi

sudo mkdir /var/log/glpi
sudo chown www-data /var/log/glpi

sudo touch /var/www/glpi/inc/downstream.php
echo "<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
    require_once GLPI_CONFIG_DIR . '/local_define.php';
}" > /var/www/glpi/inc/downstream.php

sudo touch /etc/glpi/local_define.php
echo "<?php
define('GLPI_VAR_DIR', '/var/lib/glpi/files');
define('GLPI_LOG_DIR', '/var/log/glpi');" > /etc/glpi/local_define.php

# Partie Apache -----------------------------------------------------------------
site=$(whiptail --inputbox "Pour changer le nom du site, saisissez le nouveau nom du site" 8 39 support.m2l --title "Nom du site" 3>&1 1>&2 2>&3)
sudo touch /etc/apache2/sites-available/$ite.conf

echo "<VirtualHost *:80>
    ServerName $site

    DocumentRoot /var/www/glpi/public

    # If you want to place GLPI in a subfolder of your site (e.g. your virtual host is serving multiple applications),
    # you can use an Alias directive. If you do this, the DocumentRoot directive MUST NOT target the GLPI directory itself.
    # Alias "/glpi" "/var/www/glpi/public"

    <Directory /var/www/glpi/public>
        Require all granted

        RewriteEngine On

        # Redirect all requests to GLPI router, unless file exists.
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
    
    <FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php8.2-fpm.sock|fcgi://localhost/"
    </FilesMatch>
    
</VirtualHost>" > /etc/apache2/sites-available/$site.conf

sudo a2ensite $site.conf
sudo a2dissite 000-default.conf
sudo a2enmod rewrite
sudo systemctl restart apache2


sudo apt-get install php8.2-fpm
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php8.2-fpm
sudo systemctl reload apache2

sudo touch /etc/php/8.2/fpm/php.ini
echo "session.cookie_httponly = on" > /etc/php/8.2/fpm/php.ini
sudo systemctl restart php8.2-fpm.service


# echo > (remplace) ; echo >> (ajoute à la fin)
