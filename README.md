GitView
=======

Mining GitHub projects to learn about open source software development communities and practices. To view a demo of this project please see http://sqrlab.science.uoit.ca/GitHubMining/

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
5. [Eclipse metrics plugin](http://sourceforge.net/projects/metrics2/), version 1.3.8
6. [Eclipse Metrics xml Reader](https://github.com/sqrlab/eclipse_metrics_xml_reader)
7. [Eclipse Import tool](https://github.com/dataBaseError/eclipse-import-projects-plugin)
8. [Maven](https://maven.apache.org/) version 2.2.1, used to create eclipse project files
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

2. Log into the mysql server.

        mysql -u <username> -p

2. Create github_data database using the [create file](doc/database.sql). 

		source ./doc/database.sql

3. Create project_stats database using the [create file](doc/stats_database.sql)

        source ./doc/stats_database.sql

4. ** Note, the following is current development**. Create metrics database using the [create file](doc/metrics_db.sql)

        source ./doc/metrics_db.sql

5. Exit the mysql server

        exit

### Setup the Web Server

1. Install [Apache2](https://httpd.apache.org/)

		sudo apt-get install apache2

2. Restart Apache2

		sudo /etc/init.d/apache2 restart

3. Install PHP5

		sudo apt-get install php5 libapache2-mod-php5 php5-mysql

4. Clone project into `/var/www/html/` or set up [virtual site](#setting-up-virtual-site)

5. Changing the api root url. Open the javascript [graphing file](js/results.js) and change the following line to point the api folder within the project.

        var rootURL = "http://git_data.dom/api";

6. Go to page `http://localhost/GitView/index.php`

7. *Please note*, depending on whether the project is placed in the `/var/www/html/` or is a virtual site the relative paths to the resources may need to change. The paths are currently set up for a virtual server. A set up that places the project directly into `/var/www/html/` will require to adjust:
    * [header.php](templates/header.php), change the href for css resources.
    * [footer.php](templates/footer.php), change the href for the js resources.

Usually this just requires changing a path like:

        <link href="../css/smoothness/jquery-ui-1.10.3.custom.min.css" rel="stylesheet" />

To:

        <link href="./css/smoothness/jquery-ui-1.10.3.custom.min.css" rel="stylesheet" />


#### Setting up Virtual Site

*Note* not required if the project is cloned to `/var/www/html/`

1. Open `/etc/apache2/sites-enabled/000-default.conf` and add the following to the end of the file. 

		<VirtualHost *:80>
		    ServerAdmin test@git_data.dom
		    DocumentRoot "<project_location>"
		    ServerName git_data.dom
		    ServerAlias git_data.dom
		    ErrorLog "/var/log/apache2/git_data.dom-error_log"
		    CustomLog "/var/log/apache2/git_data.dom-access_log" common
		    <Directory "<project_location>">
		            DirectoryIndex index.php
		            AddHandler php5-script php
		            Options -Indexes +FollowSymLinks +MultiViews
		            AllowOverride All
		            Order allow,deny
		            allow from all
		            Require all granted
		    </Directory>
		</VirtualHost>

2. Modify the `<project_location>` field in `DocumentRoot` and `Directory` to the location of the project.

#### Cleaning web server repo

1. Apache by default will show the directory listings of the folder for the website. To remove this open `/etc/apache2/sites-enabled/000-default.conf`

2. Add in the following (if you followed the steps for creating the virtual site only modifiy the *Options* line):

		<Directory /var/www/html/GitView/>
                Options -Indexes +FollowSymLinks +MultiViews
                AllowOverride all
                Order allow,deny
                allow from all
        </Directory>

3. Now that the directories are not displayed by default we now want to block the directories that are not required. The following is a list of the folders that require r-x permission for the web server to work:
    * api
    * css
    * img
    * inc
    * js
    * src
    * templates

4. All other folder's can be removed or have their permissions revoked for both group and other users.

        sudo chmod go-rx <folder name>

5. Finally, the two files required in the root directory are: 
    * add_new.php
    * index.php

6. All other files can be deleted or the permissions can be remoked for both group and other users.

        sudo chmod go-rx <file name>

## Collecting Data

This section outlines how to collect and then parse the data to show on the website tool.

### Collecting Data from GitHub

**Please note** this script executed in this section may take a very long time (depending on the size of the project).

1. Run the [scraper](src/scraper/scraper) script on the desired project passing the repository owner and the repository's name as arguments. For example:

		bash scraper ACRA acra

### Parsing the Collected Data

**Please note** this section relies on the completion of the previous section for the same repository. In order to parse [ACRA/acra](https://github.com/ACRA/acra) it must first be called with the [scraper script](#collecting-data-from-github).

**Please note** this script executed in this section may take a very long time (depending on the size of the project).

1. Execute the [parser](src/parser/parser) script to actually store the values in the database.

		bash parser ACRA acra false

3. Proceed to `http://localhost/GitView/index.php` which should now be displaying the newly parsed project. *Note* this can be done before the parser is finished since the changes will be visible on the site immediately.

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

		sudo apt-get install python2.7

5. Download the [Eclipse metrics XML reader](https://github.com/sqrlab/eclipse_metrics_xml_reader)

#### Installing ADT plug-in for Eclipse

1. Installing the [ADT plug-in](https://developer.android.com/sdk/installing/installing-adt.html#Download) for Eclipse by adding the source:

		https://dl-ssl.google.com/android/eclipse/

2. Re-open eclipse which will prompt you to install the Android SDK.

3. Open the *Android SDK Manager*

4. Select all the required SDK Platform version. If an older version of the target application used an earlier version of the Android SDK then that version will be required as well. The most flexible method is to install every Android version. **Note** Downloading and install may take sometime.

#### Installing Import plug-in for Eclipse

1. Clone the [repository](https://github.com/dataBaseError/eclipse-import-projects-plugin)

2. Follow the [instructions on installing](https://github.com/dataBaseError/eclipse-import-projects-plugin#installation)

### Collecting Metrics

1. Open the [metric_compiler](src/metrics_calc/metric_compiler) script and adjust the following variables:
    * `ECLIPSE_LOCATION` the location where the eclipse binary is located.
    * `WORKSPACE` the location of the workspace to use.
    * `SCRIPT_WORK_DIR` the location to create temporary files.
    * `TEMPLATE_BUILD_FILE_LOCATION` the location of the template [build.xml](src/metrics_calc/build.xml) file.
    * `XML_CONVERTER_LOCATION` the location of the clone of [xml to csv program](https://github.com/sqrlab/eclipse_metrics_xml_reader).

2. Open the [metrics_calc.rb](src/metrics_calc/metrics_calc.rb) script and adjust `project_dir`, `output_dir`, `log_file` and `log` as desired
	* `project_dir` is the location the project will be cloned to and each commit is checked out.
	* `output_dir` is the directory to output the metrics csv files to.
	* `log_file` is the directory where the log files would be placed.
	* `log` whether to ouput the log file or not.
    * `headless` whether to run with xvfb or not.
    * `metrics_compiler` the location of the [metrics compiler](src/metrics_calc/metric_compiler) shell script.

3. Execute the script

		ruby metrics_calc.rb

4. This can take a very long time and make it harder to use the computer is running on (eclipse will open and take focus and then close).

* *Note* this can also produce a large number of log and output files so it is wise to direct each of them to seperate empty directories.
