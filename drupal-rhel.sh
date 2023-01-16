#!/bin/bash
#
## Install Drupal plus pre-requisites on a RHEL9 based instance
## Apache based installation
## Inspired by https://linuxhostsupport.com/blog/how-to-install-drupal-9-cms-on-ubuntu-20-04/
#
## Variables
#
echo "Enter directory for Drupal Files"
read -p "Web Directory: " web_dir

echo "Enter a database name:"
read -p "Database Name: " db_name

echo "Enter a database username:"
read -p "Username: " db_user

echo "Choose a password for " $db_name
read -sp "Password: " db_password

echo "Choose a root password for the database"
read -sp "Root password: " sqlrootpassword
#
## Update instance and install Apache, MySQL, PHP and other utilities
#
dnf update -y
dnf install wget -y
dnf install httpd -y
dnf install mariadb mariadb-server -y
dnf module reset php
dnf module enable php:8.1 -y
dnf install php -y
dnf install php-dom php-gd php-simplexml php-xml php-opcache php-mbstring php-mysqlnd -y
#
## Configure, start and enable Apache web-server
#
sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/httpd/conf/httpd.conf
systemctl enable httpd
systemctl start httpd
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
## Create databse for Drupal
#
mysql -u root -e "CREATE DATABASE $db_name;"
mysql -u root -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';"
mysql -u root -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"
#
## Download and extract Drupal
#
cd /tmp
wget https://www.drupal.org/download-latest/tar.gz
tar -xzf tar.gz
mv drupal-* drupal
cd drupal
sudo rsync -avz . /var/www/html
chown -R apache:apache /var/www/html
chcon -Rv --type=httpd_sys_rw_content_t /var/www/html/sites/default/
systemctl restart httpd
cd /tmp
#
## System cleanup
#
rm -rf /tmp/tar.gz
rm -rf drupal