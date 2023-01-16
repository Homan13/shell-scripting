#!/bin/bash
#
## Install Wordpress plus pre-requisites on Ubuntu based instance
## Apache based installation
## Inspired by https://www.how2shout.com/linux/script-to-install-lamp-wordpress-on-ubuntu-20-04-lts-server-quickly-with-one-command/
#
## Variables
#
echo "Enter directory for Wordpress Files"
read -p "Web Directory: " web_dir

echo "Enter a database name"
read -p "Database Name: " db_name

echo "Enter a database username"
read -p "Username: " db_user

echo "Choose a password for " $db_name
read -sp "Password: " db_password

echo "Choose a root password for the database"
read -sp "Root password: " sqlrootpassword
#
## Update instance and install Apache and MySQL and other utilities
#
apt update -y && apt upgrade -y
apt install lynx -y
apt install apache2 -y
rm -rf $web_dir/index.html
apt install mariadb-server-10.6 mariadb-client-10.6 -y
apt install php8.1 -y 
apt install php-bz2 php-mysqli php-curl php-gd php-intl php-common php-mbstring php-xml -y
#
## Start and enable Apache web-server
#
sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/apache2/apache2.conf
systemctl enable apache2
systemctl start apache2
#
## Start and enable MySQL
#
systemctl enable mariadb
systemctl start mariadb
#
## MySQL secure installation
#
mysql -sfu root <<EOS
-- set root password
ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password;
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$sqlrootpassword');
-- delete anonymous users
DELETE FROM mysql.user WHERE User='';
-- delete remote root capabilities
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- drop database 'test'
DROP DATABASE IF EXISTS test;
-- also make sure there are lingering permissions to it
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- make changes immediately
FLUSH PRIVILEGES;
EOS
touch /root/.my.cnf
chmod 640 /root/.my.cnf
echo "[client]">>/root/.my.cnf
echo "user=root">>/root/.my.cnf
echo "password=$sqlrootpassword">>/root/.my.cnf
#
# Download, extract and configure WordPress
#
if test -f /tmp/latest.tar.gz
then
echo "WordPress has already been downloaded"
else
echo "Downloading WordPress installation package"
cd /tmp/ && wget "http://wordpress.org/latest.tar.gz";
fi
tar -C $web_dir -zxf /tmp/latest.tar.gz --strip-components=1
chown www-data: $web_dir -R
#
## Create wp-config and configure DB
#
mv $web_dir/wp-config-sample.php $web_dir/wp-config.php
sed -i "s/database_name_here/$db_name/g" $web_dir/wp-config.php
sed -i "s/username_here/$db_user/g" $web_dir/wp-config.php
sed -i "s/password_here/$db_password/g" $web_dir/wp-config.php
cat << EOF >> $web_dir/wp-config.php
define('FS_METHOD', 'direct');
EOF
cat << EOF >> $web_dir/.htaccess
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF
#
## Set WordPress salts
#
grep -A50 'table_prefix' $web_dir/wp-config.php > /tmp/wp-tmp-config
sed -i '/**#@/,/$p/d' $web_dir/wp-config.php
lynx --dump -width 200 https://api.wordpress.org/secret-key/1.1/salt/ >> $web_dir/wp-config.php
cat /tmp/wp-tmp-config >> $web_dir/wp-config.php && rm /tmp/wp-tmp-config -f
mysql -u root -e "CREATE DATABASE $db_name;"
mysql -u root -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';"
mysql -u root -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
#
## System Cleanup
#
rm -rf /tmp/latest.tar.gz