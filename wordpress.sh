#!/bin/bash
#
## Configure a Wordpress based LAMP stack running on a Linux instance (Amazon Linux 2, Amazon Linux 2023, RHEL 9 and Ubuntu (22.04))
## This is an Apache based installation
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

platform=$(cat /etc/*release | grep -w ^NAME | sed 's/NAME=//')
version=$(cat /etc/*release | grep -w ^VERSION | sed 's/VERSION=//')
#
## Update instance and install Apache, MariaDB, PHP and other utilities
#
if [[ $platform == '"Amazon Linux"' ]] && [[ $version == '"2"' ]]; then
   echo "Updating and installing packages on Amazon Linux 2"
   yum update -y
   yum install lynx -y
   amazon-linux-extras enable php8.1 && yum clean metadata
   curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
   bash mariadb_repo_setup --os-type=rhel  --os-version=7 --mariadb-server-version=10.9
   rm -rf /var/cache/yum
   yum makecache
   amazon-linux-extras install epel -y
   yum install httpd -y
   yum install MariaDB-server MariaDB-client jemalloc -y
   amazon-linux-extras install php8.1 -y
   yum install php-bz2 php-mysqli php-curl php-gd php-intl php-common php-mbstring php-xml -y
  
   sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/httpd/conf/httpd.conf
   systemctl enable httpd
   systemctl start httpd

   systemctl enable mariadb
   systemctl start mariadb

elif [[ $platform == '"Amazon Linux"' ]] && [[ $version == '"2023"' ]]; then
   echo "Updating and installing packages on Amazon Linux 2023"
   dnf update -y
   dnf install lynx -y
   dnf install httpd -y
   dnf install mariadb105 mariadb105-server -y
   dnf install php -y
   dnf install php-bz2 php-mysqli php-curl php-gd php-intl php-common php-mbstring php-xml -y

   sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/httpd/conf/httpd.conf
   systemctl enable httpd
   systemctl start httpd

   systemctl enable mariadb
   systemctl start mariadb

elif [[ $platform == '"Red Hat Enterprise Linux"' ]]; then
   echo "Updating and installing packages on Red Hat Enterprise Linux"
   dnf update -y
   dnf install lynx wget -y
   dnf install httpd -y
   dnf install mariadb mariadb-server -y
   dnf module reset php
   dnf module enable php:8.1 -y
   dnf install php -y
   dnf install php-bz2 php-mysqli php-curl php-gd php-intl php-common php-mbstring php-xml -y

   sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/httpd/conf/httpd.conf
   systemctl enable httpd
   systemctl start httpd

   systemctl enable mariadb
   systemctl start mariadb

elif [[ $platform == '"Ubuntu"' ]]; then
   echo "Updating and installing packages on Ubuntu"
   apt update -y && apt upgrade -y
   apt install lynx -y
   apt install apache2 -y
   rm -rf $web_dir/index.html
   apt install mariadb-server-10.6 mariadb-client-10.6 -y
   apt install php8.1 -y 
   apt install php-bz2 php-mysql php-curl php-gd php-intl php-common php-mbstring php-xml -y

   sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/apache2/apache2.conf
   systemctl enable apache2
   systemctl start apache2

   systemctl enable mariadb
   systemctl start mariadb
   
else
   echo "Unsupported version of Linux"

fi
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
## Download, extract and configure WordPress
#
if test -f /tmp/latest.tar.gz; then
   echo "WordPress has already been downloaded"
else
   echo "Downloading WordPress installation package"
   cd /tmp/ && wget "http://wordpress.org/latest.tar.gz";
   tar -C $web_dir -zxf /tmp/latest.tar.gz --strip-components=1
   if [[ $platform == '"Amazon Linux"' ]] || [[ $platform == '"Red Hat Enterprise Linux"' ]]; then
      chown apache: $web_dir -R
   else [[ $platform == '"Ubuntu"' ]]
      chown www-data: $web_dir -R
      systemctl restart apache2
   fi
fi
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