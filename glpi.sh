#!/bin/bash
# Script d'installation de GLPI
# Par Logan Le Paire
# Version 2
#---------------------------------------------------------------------------


sudo apt-get update && sudo apt-get upgrade -y


sudo apt-get install apache2 php mariadb-server -y
sudo apt-get install php-xml php-common php-json php-mysql php-mbstring php-curl php-gd php-intl php-zip php-bz2 php-imap php-apcu -y
sudo apt-get install php-ldap -y

sudo mysql_secure_installation # (n,y,y,y,y,y)
<<comment
sudo mysql -e "UPDATE mysql.user SET Password = PASSWORD('CHANGEME') WHERE User = 'root'"
sudo mysql -e "DROP USER ''@'localhost'"
sudo mysql -e "DROP USER ''@'$(hostname)'"
sudo mysql -e "DROP DATABASE test"
#sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -e "FLUSH PRIVILEGES"
comment

namedb=$(whiptail --inputbox "Pour changer le nom de la Base de Donnée, saisissez le nouveau nom" 8 39 db578_glpi --title "Nom de la Base de Donnée" 3>&1 1>&2 2>&3)
userdb=$(whiptail --inputbox "Pour changer le nom d'utilisateur de la Base de Donnée, saisissez le nouveau nom" 8 39 glpidb_adm --title "Nom de l'utilisateur de la Base de Donnée" 3>&1 1>&2 2>&3)
mdpdb=$(whiptail --inputbox "Pour changer le mot de passe de la Base de Donnée, saisissez le nouveau mot de passe" 8 39 MotDePasseRobuste --title "Mot de passe de la Base de Donnée" 3>&1 1>&2 2>&3)
#echo -n "Hit me with that server name: "; read serverName
#echo "${serverName}!"

#sudo mysql -u root #-p
#sudo mysql -u root -e "CREATE DATABASE db578_glpi; GRANT ALL PRIVILEGES ON db578_glpi.* TO glpidb_adm@localhost IDENTIFIED BY "MotDePasseRobuste"; FLUSH PRIVILEGES;"

sudo mysql -u root -e "CREATE DATABASE $namedb ; GRANT ALL PRIVILEGES ON $namedb.* TO '$userdb'@localhost IDENTIFIED BY '$mdpdb'; FLUSH PRIVILEGES;"


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
sudo service apache2 start
site=$(whiptail --inputbox "Pour changer le nom du site, saisissez le nouveau nom du site" 8 39 support.m2l.local --title "Nom du site / Nom de domaine" 3>&1 1>&2 2>&3)
sudo touch /etc/apache2/sites-available/$site.conf

echo '<VirtualHost *:80>
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
    SetHandler "proxy:unix:/run/php/php8.1-fpm.sock|fcgi://localhost/"
    </FilesMatch>
    
</VirtualHost>' > /etc/apache2/sites-available/$site.conf

sudo a2ensite $site.conf
sudo a2dissite 000-default.conf
sudo a2enmod rewrite
sudo systemctl restart apache2


sudo apt install php8.1-fpm -y
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php8.1-fpm
sudo systemctl reload apache2


sudo sed -i "s/.*session.cookie_httponly.*/session.cookie_httponly = on/" /etc/php/8.1/fpm/php.ini
sudo systemctl restart php8.1-fpm.service


# Desactiver la signature web d'Apache Web et serveur token
echo "ServerSignature Off" >> /etc/apache2/apache2.conf
echo "ServerTokens Prod" >> /etc/apache2/apache2.conf
#
# Cacher la vervion de PHP
sed -i 's/.expose_php.*/expose_php = Off/' /etc/php5/apache2/php.ini
sudo sed -i "s/.*expose_php.*/expose_php = Off/" /etc/php5/apache2/php.ini
sudo service apache2 restart

# Certificat SSL --------------------------------------------------------------------------------------------------------------------
sudo a2enmod ssl
sudo apt-get install certbot python3-certbot-apache -y
sudo certbot --apache --agree-tos --redirect --hsts -d $site --email llepaire@mdnpedago.fr   #Active le certificat en y ajoutant le nom de domaine
#echo "0 5 * * * /usr/bin/certbot renew --quiet"> /etc/cron.daily/certbot
echo "0 5 * * * /usr/bin/certbot renew --quiet"> /etc/crontab
sudo systemctl restart apache2

#sudo crontab -e
#0 5 * * * /usr/bin/certbot renew --quiet

#sudo rm /var/www/glpi/install/install.php
# echo > (remplace) ; echo >> (ajoute à la fin)
