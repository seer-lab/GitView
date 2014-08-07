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
    2. Run the scraper script with the owner and the repository as arguments from the 'src' folder, eg:
        bash scraper aptana Pydev
    3. Enter your github username when prompted for a username followed by your github password. The credentials are required to increase the rate limit of github api requests (from 100 per hour to 5000 per hour).
    4. Wait until the scraping script identifies it finished successfully.

4. Parsing the data
    - Depending on the size of the repository this script may take a significant amount of time to complete.

    1. Open parser script (in src/) and change 'REPO_OWNER' and 'REPO_NAME' to their the desired values. Eg:
        REPO_OWNER=aptana
        REPO_NAME=Pydev
    2. (OPTIONAL) If you want to test that the parsing script will work before writing information to the database. Change the 'TEST' variable to 'true'. Please note this will generate a log file which can be fairly large (located in parse_log/). Otherwise set 'TEST' to false to write to the database.
        TEST=true
    3. Run the parser script:
        bash parser
    4. Wait until the progress bar fills completed or the percent complete reaches 100%.
        - Note the progress measure is not in time! It is in files completed, the time it takes to complete 1 file can vary based on the size of the file and the complexity of the patches applied to the files.

5. Viewing results
    1. The results can be hosting a local website. Once results are parsed (or in the process of being parsed) they will show on the website.

6. Experimental Metric calculations

    1. Add the project to eclipse (To be automated)

    2. Adjust the [build.xml](ant_build/build.xml) so that the values fit the target project (to be automated). For example, if the target project's name is GitHubMining the resulting xml file would be:

    ```
    <?xml version="1.0" encoding="UTF-8"?>
    <project name="GitHubMining" default="build" basedir=".">
        <target name="init">
           <tstamp/>
        </target>

        <target name="build" depends="init">
          <eclipse.refreshLocal resource="GitHubMining" depth="infinite"/>
          <metrics.enable projectName="GitHubMining"/>
          <eclipse.build 
            ProjectName="GitHubMining" 
            BuildType="full" 
            errorOut="errors.xml" 
            errorFormat="xml" 
            failOnError="true"/>
          <metrics.export 
            projectName="GitHubMining"
            file="metrics-${DSTAMP}-${TSTAMP}.xml"/>
        </target>

    </project>
    ```

    3. Adjust the variables in metric_compiler to own setup (ECLIPSE_LOCATION, WORKSPACE, BUILD_FILE_LOCATION)

    4. Run [metric_compiler](ant_build/metric_compiler)
