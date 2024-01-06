#!/bin/bash
#
## Configure a Drupal based LAMP stack running on a Linux instance (Amazon Linux 2, Amazon Linux 2023, RHEL 9 and Ubuntu (22.04))
## This is an Apache based installation
## Inspired by https://linuxhostsupport.com/blog/how-to-install-drupal-9-cms-on-ubuntu-20-04/
#
## Variables
#
echo "Enter directory for Drupal Files"
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
   amazon-linux-extras enable php8.2 && yum clean metadata
   curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
   bash mariadb_repo_setup --os-type=rhel  --os-version=7 --mariadb-server-version=10.11
   rm -rf /var/cache/yum
   yum makecache
   amazon-linux-extras install epel -y
   yum install httpd -y
   yum install MariaDB-server MariaDB-client jemalloc -y
   amazon-linux-extras install php8.2 -y
   yum install php-dom php-gd php-simplexml php-xml php-opcache php-mbstring php-mysqlnd -y

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
   dnf install php-dom php-gd php-simplexml php-xml php-opcache php-mbstring php-mysqlnd -y

   sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/httpd/conf/httpd.conf
   systemctl enable httpd
   systemctl start httpd

   systemctl enable mariadb
   systemctl start mariadb

elif [[ $platform == '"Red Hat Enterprise Linux"' ]]; then
   echo "Updating and installing packages on Red Hat Enterprise Linux"
   dnf update -y
   dnf install wget -y
   dnf install httpd -y
   dnf install mariadb mariadb-server -y
   dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
   dnf install http://rpms.remirepo.net/enterprise/remi-release-9.rpm -y
   dnf module reset php -y
   dnf module install php:remi-8.2 -y
   dnf install php -y
   dnf install php-dom php-gd php-simplexml php-xml php-opcache php-mbstring php-mysqlnd -y

   sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/httpd/conf/httpd.conf
   systemctl enable httpd
   systemctl start httpd

   systemctl enable mariadb
   systemctl start mariadb

elif [[ $platform == '"Ubuntu"' ]]; then
   echo "Updating and installing packages on Ubuntu"
   apt update -y && apt upgrade -y
   apt install dirmngr ca-certificates software-properties-common apt-transport-https curl -y
   apt install apache2 -y
   rm -rf /var/www/html/index.html
   curl -fsSL http://mirror.mariadb.org/PublicKey_v2 | sudo gpg --dearmor | sudo tee /usr/share/keyrings/mariadb.gpg > /dev/null
   echo "deb [arch=amd64,arm64,ppc64el signed-by=/usr/share/keyrings/mariadb.gpg] http://mirror.mariadb.org/repo/10.11/ubuntu/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mariadb.list
   apt update
   apt install mariadb-server mariadb-client -y
   add-apt-repository ppa:ondrej/php -y
   apt update
   apt install php8.2 -y
   apt install php8.2-dom php8.2-gd php8.2-simplexml php8.2-xml php8.2-opcache php8.2-mbstring php8.2-mysql -y

   sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
   a2enmod rewrite
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
if [[ $platform == '"Amazon Linux"' ]] || [[ $platform == '"Red Hat Enterprise Linux"' ]]; then
   chown -R apache:apache /var/www/html
else
   chown -R www-data:www-data /var/www/html
fi
if [[ $platform == '"Red Hat Enterprise Linux"' ]]; then
   chcon -Rv --type=httpd_sys_rw_content_t /var/www/html/sites/default/
fi
if [[ $platform == '"Amazon Linux"' ]] || [[ $platform == '"Red Hat Enterprise Linux"' ]]; then
   systemctl restart httpd
else
   systemctl restart apache2
fi
cd /tmp
#
## System cleanup
#
rm -rf ~/drupal.sh
rm -rf /tmp/tar.gz
rm -rf /tmp/drupal