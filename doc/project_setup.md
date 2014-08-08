Setting up to run the project
=============================

1. Install ruby1.9.3

**Please note**:
- MySQL's gem does not currently work with Ruby2.0.3

    1. Gems to install:
        - see the [required gems](doc/gems_required)

2. Install MySQL
    1. Create github_data database (store retrieved github data). 
        - Use database.sql

        1. Create Database
        2. Create database user
        3. Grant reduced set of privileges to user
        4. Create each table in the database (in order)
        5. Insert the supported file type 'java' into the database (see database.sql insert query)


    2. Create project_stats database (store parsed stats about each project). Using stats_database.sql

        1. Create Database (take into account thresholds used)
        2. Grant reduced set of privileges to user (created in previous database creation)
        3. Create each table

3. Gathering data
    - Depending on the size of the repository this script may take a significant amount of time to complete.

    1. Choose the repository that you wish to parse from github: eg.

            aptana/Pydev

    2. Run the scraper script with the owner and the repository as arguments from the `src/scraper/` folder, eg:

            bash scraper aptana Pydev

    3. Enter your github username when prompted for a username followed by your github password. The credentials are required to increase the rate limit of github api requests (from 100 per hour to 5000 per hour).

    4. Wait until the scraping script identifies it finished successfully.
        - *Note* the progress measure is not in time! The progress bar measures is in files completed. The time it takes to complete 1 file can vary based on the size of the file and the complexity of the patches applied to the files.

4. Parsing the data
    - Depending on the size of the repository this script may take a significant amount of time to complete.

    1. Run the parsing script (in `src/parser/`) with the desired repository as arguments. Eg.

            bash parser aptana Pydev

    2. (OPTIONAL) If you want to test that the parsing script will work before writing information to the database. Pass a third argument as true. Eg.

            bash parser aptana Pydev true

    3. Wait until the progress bar fills completed or the percent complete reaches 100%.
        - *Note* the progress measure is not in time! The progress bar measures is in files completed. The time it takes to complete 1 file can vary based on the size of the file and the complexity of the patches applied to the files.

## Viewing the Results

1. The results can be viewed on a locally hosted website. Once results are parsed (or in the process of being parsed) they will show on the website. All that is required is either a virtual link to the project folder or placing the project folder in `/var/www/html/`.

2. Currently a **Add New** feature is available on the website but should **not** be left available since it can easily be abused. Also, despite the Add New site parsing the targeted GitHub project it will not alert the user who requested it.

## Experimental Metric calculations

1. Adjust the variables in [metric_compiler](src/metrics_calc/metric_compiler) to own setup (*note* all paths must be absolute):

    * **ECLIPSE_LOCATION**: Location of eclipse binary file.
    * **WORKSPACE**: Location of eclipse workspace.
    * **TEMPLATE_BUILD_FILE_LOCATION**: Location of the template [build file](ant_build/build.xml).
    * **SCRIPT_WORK_DIR**: The directory the script is working in (temporary files will be created and later removed from this folder).
    * **XML_CONVERTER_PROGRAM**: The path to the eclipse metrics xml reader.

2. Open the [metrics_calc.rb](src/metrics_calc/metrics_calc.rb) script and adjust (*note* these paths can be relative):

    * **project_dir**: the directory to clone the projects too.
    * **output_dir**: the directory to output all the calculated metric csv files to.
    * **log_file**: the location of the log file directory.
    * **log**: identifies whether to log the script to the provided **log_file** directory.

3. Execute the script

        ruby metrics_calc.rb

4. This can take a very long time and make it harder to use the computer is running on (eclipse will open and take focus and then close).

* *Note* this can also produce a large number of log and output files so it is wise to direct them to empty folders.