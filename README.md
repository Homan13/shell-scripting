# My Script Collection

A collection of scripts I've used over my years working in IT and in my volunteer work. To be clear, I am actually writing many, if not most  after the fact. Why you ask? Well, I wasn't smart enough at the time to document, log and store them all. I expect these to grow over time and evolve as I remember various tasks, attempt to piece stuff back together and make updates to keep this relevant.

## Getting Started

This repository contains the following scripts;

**drupal.sh** - This script will configure a Drupal enabled LAMP stack on your Linux instance as a web server and database serving up a Drupal site. As this runs the web server and database on a single instance it is not meant for production workloads. This script is meant to be used as a learning tool helping someone rapidly launch a LAMP stack running Drupal if they've never worked with the technology before in an effort to familiarize themselves with this type of deployment. This script has been tested and confirmed against the following versions of Linux; Amazon Linux 2 (AL2), Amazon Linux 2023 (AL2023), Ubuntu (22.04) and Red Hat Enterprise Linux (RHEL) 9. LAMP stack is running the following software versions; Drupal 10.2.x, Apache 2.4.x, MariaDB 10.11.x (AL2 and Ubuntu), MariaDB 10.5.x (AL2023 and RHEL) and PHP 8.2.x. *Please Note* - may not work on Chrome. If Drupal setup does not run properly, and you're running it from Chrome, try again and use Firefox.

**wordpress.sh** - This script will configure a Wordpress enabled LAMP stack on your Linux instance as a web server and database serving up a Wordpress site. As this runs the web server and database on a single instance it is not meant for production workloads. This script is meant to be used as a learning tool helping someone rapidly launch a LAMP stack running Wordpress if they've never worked with the technology before in an effort to familiarize themselves with this type of deployment. This script has been tested and confirmed against the following versions of Linux; Amazon Linux 2 (AL2), Amazon Linux 2023 (AL2023), Ubuntu (22.04) and Red Hat Enterprise Linux (RHEL) 9. LAMP stack is running the following software versions; Wordpress 6.4.x, Apache 2.4.x, MariaDB 10.11.x (AL2 and Ubuntu) and 10.5.x (AL2023 and RHEL) and PHP 8.2.x.

**participant-report.py** - This script pulls data from two exports, MotorsportsReg participant export, and Orbits timing software export and merges them into the Sports Car Club of America (SCCA) participation report spreadsheet. I created this as the Chief Competition Director of the Washington DC Region (WDCR) of SCCA to automate this process for the competition team and speed up submission of the report post event. The results PDF supplies finishing position, car number, driver name and vehicle class, while the CSV export supplies the member ID, vehicle make and model, and the correct spelling and split of each driver's first and last name. The two are matched on driver name rather than car number, as car numbers can differ between the two exports. Drivers who enter more than one car are listed once with their best finish, and both overall position (POS) and position in class (PIC) are calculated automatically. This fills in every required column on the report except Passing Rules and Satisfactory, which do not appear in either export and still need to be entered by hand before submission. The script will warn you about any driver missing a member ID in the CSV export.

Run it with the results PDF, the CSV export, the blank SCCA template, and the name of the file you want written out;

`python3 participant-report.py results.pdf export.csv template.xlsx output.xlsx`

SCCA revises the template, and its worksheet name, from season to season. If the worksheet name has changed, pass the new one with `--sheet-name`.

The two shell scripts should be ready to launch once you download them, just make sure they are executable on the system they are being run on and let it rip! Please note, these scripts have been developed and tested on Elastic Compute Cloud (EC2) on Amazon Web Services (AWS). Some updates (packages, etc.) may need to be made if you're running these within another cloud provider or on-prem within VSphere or on a personal machine. The participant report script is run through Python rather than executed directly, see Prerequisites below.

### Prerequisites

All you need to get started with the shell scripts is a command line, and your favorite IDE for making edits.

The participant report script also needs Python 3 and two libraries, openpyxl and pdfplumber. Neither tends to be installed by default, so a virtual environment is the cleanest way to go;

```
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Run `deactivate` when you're finished. On subsequent runs you only need the `source` line again.

## Built With

* [Amazon Linux 2](https://aws.amazon.com/amazon-linux-2/?amazon-linux-whats-new.sort-by=item.additionalFields.postDateTime&amazon-linux-whats-new.sort-order=desc)
* [Amazon Linux 2023](https://aws.amazon.com/linux/amazon-linux-2023/)
* [Apache](https://httpd.apache.org/)
* [Bash](https://www.gnu.org/software/bash/)
* [Drupal](https://www.drupal.org/)
* [MariaDB](https://mariadb.org/)
* [openpyxl](https://openpyxl.readthedocs.io/)
* [pdfplumber](https://github.com/jsvine/pdfplumber)
* [PHP](https://www.php.net/)
* [Python](https://www.python.org/)
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