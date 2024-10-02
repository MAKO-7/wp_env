#!/bin/bash

# Variables
DB_NAME="wordpress"
DB_USER="wp_user"
DB_PASSWORD="admin"
DB_ROOT_PASSWORD="rootpassword123"
WP_DIRECTORY="/var/www/html/wordpress"
WP_URL="https://wordpress.org/latest.tar.gz"
APACHE_USER="www-data"
VHOST_DOMAIN="localhost"
VHOST_FILE="/etc/apache2/sites-available/$VHOST_DOMAIN.conf"

# Mise à jour des paquets du système
echo "Mise à jour des dépôts et des paquets..."
sudo apt update && sudo apt upgrade -y

# Installation d'Apache
echo "Installation d'Apache..."
sudo apt install apache2 -y

# Installation de MariaDB
echo "Installation de MariaDB..."
sudo apt install mariadb-server -y

# Installation de PHP et des extensions nécessaires pour WordPress
echo "Installation de PHP et des extensions requises..."
sudo apt install php libapache2-mod-php php-mysql php-cli php-curl php-gd php-mbstring php-xml php-xmlrpc -y

# Démarrage des services Apache et MariaDB
echo "Démarrage d'Apache et MariaDB..."
sudo systemctl start apache2
sudo systemctl start mariadb

# Sécurisation de MariaDB
echo "Sécurisation de MariaDB..."
sudo mysql_secure_installation <<EOF

y
$DB_ROOT_PASSWORD
$DB_ROOT_PASSWORD
y
y
y
y
EOF

# Création de la base de données pour WordPress
echo "Création de la base de données WordPress..."
sudo mysql -u root -p"$DB_ROOT_PASSWORD" -e "CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
sudo mysql -u root -p"$DB_ROOT_PASSWORD" -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
sudo mysql -u root -p"$DB_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -u root -p"$DB_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Téléchargement de la dernière version de WordPress
echo "Téléchargement de WordPress..."
wget $WP_URL -P /tmp

# Extraction de WordPress dans le répertoire de destination
echo "Extraction de WordPress..."
sudo tar -xzf /tmp/latest.tar.gz -C /var/www/html

# Configuration des permissions sur les fichiers WordPress
echo "Configuration des permissions..."
sudo chown -R $APACHE_USER:$APACHE_USER $WP_DIRECTORY
sudo chmod -R 755 $WP_DIRECTORY

# Créer un fichier wp-config.php à partir de wp-config-sample.php
echo "Configuration du fichier wp-config.php..."
cp $WP_DIRECTORY/wp-config-sample.php $WP_DIRECTORY/wp-config.php
sed -i "s/database_name_here/$DB_NAME/" $WP_DIRECTORY/wp-config.php
sed -i "s/username_here/$DB_USER/" $WP_DIRECTORY/wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" $WP_DIRECTORY/wp-config.php

# Création d'un Virtual Host pour WordPress
echo "Création du Virtual Host pour $VHOST_DOMAIN..."

sudo bash -c "cat > $VHOST_FILE" <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@$VHOST_DOMAIN
    ServerName $VHOST_DOMAIN
    DocumentRoot $WP_DIRECTORY
    <Directory $WP_DIRECTORY>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/$VHOST_DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$VHOST_DOMAIN-access.log combined
</VirtualHost>
EOF

# Activer le Virtual Host et le module rewrite pour WordPress
echo "Activation du Virtual Host et du module rewrite..."
sudo a2ensite $VHOST_DOMAIN.conf
sudo a2enmod rewrite

# Modifier le fichier hosts pour résoudre le domaine localement
echo "Ajout de $VHOST_DOMAIN dans /etc/hosts..."
sudo bash -c "echo '127.0.0.1 $VHOST_DOMAIN' >> /etc/hosts"

# Redémarrer Apache pour appliquer les modifications
echo "Redémarrage d'Apache..."
sudo systemctl restart apache2

# Terminé
echo "Installation de WordPress terminée ! Visitez http://$VHOST_DOMAIN pour terminer la configuration."
