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
dom=$(whiptail --inputbox "Pour changer le nom de domaine, saisissez le nouveau nom de domaine" 8 39 support.lolodom.local --title "Nom de domaine" 3>&1 1>&2 2>&3)
sudo touch /etc/apache2/sites-available/$dom.conf

echo "<VirtualHost *:80>
    ServerName support.it-connect.tech

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
</VirtualHost>" > /etc/apache2/sites-available/$dom.conf


# > (remplace) ; >> (ajoute à la fin)
