# My Shell Script Collection

A collection of shell scripts I've used over my years working in IT. To be clear, I am actually writing many, if not most (to be read as everything) after the fact. Why you ask? Well, I wasn't smart enough at the time to document, log and store them all. I expect these to grow over time and evolve as I remember various tasks, attempt to piece stuff back together and make updates to keep this relevant.

## Getting Started

This repository contains the following scripts;

**drupal.sh** - This script will configure a Drupal enabled LAMP stack on your Linux instance as a web server and database serving up a Drupal site. As this runs the web server and database on a single instance it is not meant for production workloads. This script is meant to be used as a learning tool helping someone rapidly launch a LAMP stack running Drupal if they've never worked with the technology before in an effort to familiarize themselves with this type of deployment. This script has been tested and confirmed against the following versions of Linux; Amazon Linux 2 (AL2), Amazon Linux 2023 (AL2023), Ubuntu (22.04) and Red Hat Enterprise Linux (RHEL) 9. LAMP stack is running the following software versions; Drupal 10.0.x, Apache 2.4.x, MariaDB 10.9.x (AL2), MariaDB 10.6.x (AL2023, Ubuntu and RHEL) and PHP 8.1.x. *Please Note* - may not work on Chrome. If Drupal setup does not run properly, and you're running it from Chrome, try again and use Firefox.

**wordpress.sh** - This script will configure a Wordpress enabled LAMP stack on your Linux instance as a web server and database serving up a Wordpress site. As this runs the web server and database on a single instance it is not meant for production workloads. This script is meant to be used as a learning tool helping someone rapidly launch a LAMP stack running Wordpress if they've never worked with the technology before in an effort to familiarize themselves with this type of deployment. This script has been tested and confirmed against the following versions of Linux; Amazon Linux 2 (AL2), Amazon Linux 2023 (AL2023), Ubuntu (22.04) and Red Hat Enterprise Linux (RHEL) 9. LAMP stack is running the following software versions; Wordpress 6.1.x, Apache 2.4.x, MariaDB 10.9.x (AL2) and 10.6.x (AL2023, Ubuntu and RHEL) and PHP 8.1.x.

These scripts should be ready to launch once you download them, just make sure it is executable on the system it is being run on and let it rip! Please note, these scripts have been developed and tested on Elastic Compute Cloud (EC2) on Amazon Web Services (AWS). Some updates (packages, etc.) may need to be made if you're running these within another cloud provider or on-prem within VSphere or on a personal machine.

### Prerequisites

All you need to get started with these scripts is a command line, and your favorite IDE for making edits.

## Built With

* [Amazon Linux 2](https://aws.amazon.com/amazon-linux-2/?amazon-linux-whats-new.sort-by=item.additionalFields.postDateTime&amazon-linux-whats-new.sort-order=desc)
* [Amazon Linux 2023](https://aws.amazon.com/linux/amazon-linux-2023/)
* [Apache](https://httpd.apache.org/)
* [Bash](https://www.gnu.org/software/bash/)
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