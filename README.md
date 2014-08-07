GitHubMining
============

Mining GitHub projects to learn about open source software development communities and practices.

## Prerequisites

1. [Xubuntu](http://xubuntu.org/) or some similar Ubuntu variant
2. [Ruby](https://www.ruby-lang.org/en/) version 1.9.3
3. [Apache2](https://httpd.apache.org/)
4. [MySQL](https://www.mysql.com/) version 14.14, distribution 5.5.38
5. [PHP](http://php.net/) version 5.5.9
6. For required gems (see [Required Gems File](doc/gems_required))

### Current Development Prerequisites

1. [Java](https://www.java.com/en/) version 1.7.0_51
2. [Ant](https://ant.apache.org/) version 1.9.3 
3. [Eclipse Luna](http://eclipse.org/)
4. [Eclipse ADT plugin](https://developer.android.com/sdk/installing/installing-adt.html) **Note** Eclipse ADT with SDK since it uses it has issues installing the import plug-in.
5. [Eclipse metrics plugin](http://sourceforge.net/projects/eclipse-metrics/), version 1.3.6
	- http://sourceforge.net/projects/metrics2/
6. [Eclipse Metrics xml Reader](https://github.com/sqrlab/eclipse_metrics_xml_reader)
7. [Eclipse Import tool](https://github.com/dataBaseError/eclipse-import-projects-plugin)
8. [Maven](https://maven.apache.org/) version 2.2.1
9. [Python](https://www.python.org/) version 2.7.6, required by Eclipse Metrics XML reader

## Setup notes

Please see the [project setup notes](doc/project_setup) for a more detailed explanation on how to setup the project.

### Setup Ruby

1. Install ruby1.9.3

		sudo apt-get install ruby1.9.3

2. Install the required [Gems](doc/gems_required). An example would be:

		gem install mysql

### Setup the Database

In order to store the data you must use mysql

1. Install MySQL and enter the root user's password

		sudo apt-get install mysql-server-5.5 mysql-common mysql-client-5.5

2. Create github_data database using the [create file](doc/database.sql)

		mysql -u <username> -p
		source ./doc/database.sql

3. Create project_stats database using the [create file](doc/stats_database.sql)

		mysql -u <username> -p
		source ./doc/stats_database.sql

### Setup the Web Server

1. Install [Apache2](https://httpd.apache.org/)

		sudo apt-get install apache2

2. Restart Apache2

		sudo /etc/init.d/apache2 restart

3. Install PHP5

		sudo apt-get install php5 libapache2-mod-php5 php5-mysql

4. Clone project into /var/www/html/ or set up virtual site.

5. Go to page `http://localhost/GitHubMining/index.php`

## Collecting Data

This section outlines how to collect and then parse the data to show on the website tool.

### Collecting Data from GitHub

**Please note** this script executed in this section may take a very long time (depending on the size of the project).

1. Run the script on the desired project passing the repository owner and the repository's name as arguments. For example:

		bash scraper ACRA acra

### Parsing the Collected Data

**Please note** this section relies on the completion of the previous section for the same repository. In order to parse [ACRA/acra](https://github.com/ACRA/acra) it must first be called with the [scraper script](#collecting-data-from-github).
**Please note** this script executed in this section may take a very long time (depending on the size of the project).

1. Execute the script to actually store the values in the database.

		bash parser ACRA acra false

3. Proceed to `http://localhost/GitHubMining/index.php` which should now be displaying the newly parsed project. *Note* this can be done before the parser is finished since the changes will be visible on the site immediately.

## Current Work

This section outlines how to setup the metrics collecting script.

### Installing Dependencies

1. To install Oracle's Java, please follow this [guide](http://cs-club.ca/wiki/index.php/Installing_Oracle_Java_on_Ubuntu)

2. Install Maven

		sudo apt-get install maven2

3. Get [Eclipse Luna](https://www.eclipse.org/downloads/packages/eclipse-standard-44/lunar) and extract it to a preferred location.

4. Installing the [Metrics plug-in](http://metrics2.sourceforge.net/) for Eclipse by adding the source:

		http://metrics2.sourceforge.net/update/

4. Install Python

		sudo apt-get install python2

5. Download the [Eclipse metrics XML reader](https://github.com/sqrlab/eclipse_metrics_xml_reader)

#### Installing ADT plug-in for Eclipse

1. Installing the [ADT plug-in](https://developer.android.com/sdk/installing/installing-adt.html#Download) for Eclipse by adding the source:

		https://dl-ssl.google.com/android/eclipse/

2. Open the *Android SDK Manager*

3. Select all the required SDK Platform version. If an older version of the target application used an earlier version of the Android SDK then that version will be required as well. The most flexible method is to install every Android version. **Note** Downloading and install may take sometime.

#### Installing Import plug-in for Eclipse

1. Clone the [repository](https://github.com/dataBaseError/eclipse-import-projects-plugin)

2. Follow the [instructions on installing](https://github.com/dataBaseError/eclipse-import-projects-plugin#installation)

### Collecting Metrics

1. Open the [script](ant_build/metric_compiler) and adjust the necessary variables

2. Execute the script

		bash metric_compiler

3. If successful each project folder should contain a `.csv` file for the package, class and method level. 