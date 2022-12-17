# My Shell Script Collection

A collection of shell scripts I've used over my years working in IT. To be clear, I am actually writing many, if not most (read as everything) after the fact. Why you ask? Well, I wasn't smart enough at the time to document, log and store them all. I expect these to grow over time and evolve as I remember various tasks, attempt to piece stuff back together and make updates to keep this relevant.

## Getting Started

This repository contains the following scripts;

**drupal.sh** - This script will configure your VM/server/instance to serve as a web server and database to serve up a Drupal site. As this runs the web server and database on a signal VM/server/instance it is not meant for production workloads. This script is meant to be used as a learning tool helping someone rapidly launch a LAMP stack running Drupal if they've never worked with the technology before in an effort to familiarize themselves with this type of deployment. This script is running the following versions; Drupal 9.49, Apache 2.4.54, MariaDB 10.5 and PHP8.1.

**wordpress.sh** - This script will configure your VM/server/instance to serve as a web server and database to serve up a Wordpress site. As this runs the web server and database on a signal VM/server/instance it is not meant for production workloads. This script is meant to be used as a learning tool helping someone rapidly launch a LAMP stack running Drupal if they've never worked with the technology before in an effort to familiarize themselves with this type of deployment. This script is running the following versions; Wordpress 6.1.1, Apache 2.4.54, MariaDB 10.5 and PHP8.1.

In the case of both scripts, please take note of the variables section at the top of each script. These will need to be updated prior to deploying these stacks.

```
db_name="{changeme}"
db_user="{changeme}"
db_password="{changeme}"
sqlrootpassword="{changeme}"
```

In the above sample, simply substitute your selected valuable for the {changeme} section, being sure to eliminate the brackets. Once you have done so you can save the script, make sure its executable and execute the script.

### Prerequisites

All you need to get started with these scripts is a command line, and your favorite IDE for making edits.

## Built With

* [Amazon Linux 2](https://aws.amazon.com/amazon-linux-2/?amazon-linux-whats-new.sort-by=item.additionalFields.postDateTime&amazon-linux-whats-new.sort-order=desc)
* [Apache](https://httpd.apache.org/)
* [Bash](https://www.gnu.org/software/bash/)
* [CentOS](https://www.centos.org/)
* [Drupal](https://www.drupal.org/)
* [MariaDB](https://mariadb.org/)
* [PHP](https://www.php.net/)
* [Red Hat Enterprise Linux](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux)
* [Wordpress](https://wordpress.com/)

## Contributing

Coming soon

## Versioning

Coming Soon

## Authors

* **Kevin Homan**

## License

Coming Soon

## Acknowledgment

* **Heyan Maurya** - [Script to install LAMP & WordPress on Ubuntu 20.04 LTS server quickly with one command](https://www.how2shout.com/linux/script-to-install-lamp-wordpress-on-ubuntu-20-04-lts-server-quickly-with-one-command/) - Inspiration behind the Wordpress installation script
* [How to Install Drupal 9 CMS on Ubuntu 20.04](https://linuxhostsupport.com/blog/how-to-install-drupal-9-cms-on-ubuntu-20-04/) - Inspiration behind the Drupal installation script
* **Billie Thompson** - [PurpleBooth](https://github.com/PurpleBooth) - Inspiration for the README layout you see here