###############################################################################
# Copyright (c) 2014 Jeremy S. Bradbury, Joseph Heron
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###############################################################################

#require 'fileutils'
require_relative '../database/database_interface'
require_relative '../progress/progress'
require_relative 'csv_parser'

APP_TITLE = 'Metric Calculator'

def checkForwardSlash(folder)
    if folder[-1] != "/"
        folder = "#{folder}/"
    end
    folder
end

def fixDir(folder)

    folder = checkForwardSlash(folder)
    # Ensure ruby handles the ~ symbol properly
    if folder[0] == '~' 
        folder = "#{%x(echo ~).chomp!}#{folder[1..-1]}"
    end
    folder
end

RESULTS_REGEX = /(FAILED|SUCCESS): \/([A-Za-z0-9 ]*)\/ ([A-Za-z0-9]*)([A-Za-z0-9 ]*)/

project_dir = fixDir("~/source_code/acra/")
output_dir = fixDir("~/source_code/GitView/acra_metrics")
log_file_dir = "~/source_code/GitView/ant_build/"
log = false
headless = true

metric_compiler = "~/source_code/GitView/src/metrics_calc/metric_compiler"

progress_indicator = Progress.new(APP_TITLE)

csv_parser = CSVParser.new

# Ensure the directory is not already in use.
if Dir.exists?(project_dir) && Dir[project_dir].empty?
    raise "Directory already exists with content!"
end

con = Github_database.createConnection

Dir.chdir(project_dir)

Github_database.getRepos(con).each do |repo_id, repo_name, repo_owner|

    # Clone the repository.
    puts "#{repo_owner}/#{repo_name}"
    %x(git clone git@github.com:#{repo_owner}/#{repo_name}.git)
    Dir.chdir(repo_name)
    #git@github.com:ACRA/acra.git

    previous_result = ''

    csv_parser.setup_repo(repo_owner, repo_name)

    commits = Github_database.getCommitsByDate(con, repo_owner, repo_name)
    progress_indicator.total_length = commits.length

    commits.each do |commit|
        #c.#{SHA}, u.#{DATE}

        # Display the relevant information
        progress_indicator.percentComplete(["Repository = #{repo_owner}/#{repo_name}", "Current commit = #{commit[Github_database::SHA]}"])

        progress_indicator.puts previous_result
        previous_result.clear

        # Check out the next commit
        %x(git checkout #{commit[Github_database::SHA]})

        redirect = ""
        if log
            redirect = "2>&1 | tee #{log_file_dir}#{repo_owner}_#{repo_name}_#{commit[Github_database::SHA][0..6]}_#{Time.now.to_s[0..-7].gsub(/\s/, '_').gsub(/:/, '-')}"
        end

        # Collect the information about the previous commit
        result = %x(bash #{metric_compiler} #{project_dir}#{repo_name}/ #{output_dir} #{commit[Github_database::SHA]} #{headless} #{redirect})

        # search through results for errors or success
        #results = result.scan(RESULTS_REGEX)

        relavent_projects = %x(ls #{output_dir}*#{commit[Github_database::SHA]}_metrics_method.csv)

        if relavent_projects && relavent_projects.length > 0

            relavent_projects.each_line do |line|

                line.scan(Regexp.new("^([A-Za-z0-9 ]+)_#{commit[Github_database::SHA]}")).each do |project| 
                    
                    # For some reason acra project is parsing its own as well as CrashReports values
                    # Might be for some reason when it fails 
                    val = "Project #{project} in version #{commit[Github_database::SHA]}"

                    # Store the results in the database
                    csv_parser.handle_all(project, commit[Github_database::SHA], commit[Github_database::DATE], output_dir)            

                    #if element[0] == 'SUCCESS'
                        # Completed successfully
                    # assume success if file is present
                    val += " succeed"

                    #elsif element[0] == 'FAILED'
                        # Failed
                    #    val += " failed #{element[3]}"
                    #end
                    previous_result << "#{val}"
                end
            end
        else
            previous_result << "Failed to find any projects!"
        end

    end

    # Exit after the first project for testing purposes
    Kernel.exit(true)
end


# "#{output_dir}/${project_name}_${project_version}_metrics_package.csv"
# "#{output_dir}/${project_name}_${project_version}_metrics_class.csv"



