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

require_relative '../database/database_interface'
require_relative '../progress/progress'
require_relative 'csv_parser'
require_relative '../database/metrics_interface'
require 'fileutils'

# Examples:
# 1. This will only collect the metrics for given project ACRA/acra
# ruby metrics_calc.rb ACRA acra
# 2. This will go through all stored projects and collect the metrics for each project
# ruby metrics_calc.rb

APP_TITLE = 'Metric Calculator'

# Ensure a folder path has a forward slash as the very last character.
def checkForwardSlash(folder)
    if folder[-1] != "/"
        folder = "#{folder}/"
    end
    
    return folder
end

# Fix the given directory to be correctly formated for ruby
def fixDir(folder)

    folder = checkForwardSlash(folder)
    # Ensure ruby handles the ~ symbol properly
    if folder[0] == '~' 
        folder = "#{checkForwardSlash(Dir.home)}#{folder[1..-1]}"
    end
    return folder
end

# Get the formated string of a github clone url
def getCloneString(repo_owner, repo_name)
    return "git@github.com:#{repo_owner}/#{repo_name}.git"
end

# Ensure the project can be cloned properly.
def verifyGitHubProject(folder, repo_owner, repo_name)

    if !Dir.exists?("#{folder}#{repo_name}")
        # Clone the project
        Dir.chdir(folder)
        %x(git clone #{getCloneString(repo_owner, repo_name)})
        Dir.chdir(repo_name)
    else
        Dir.chdir("#{folder}#{repo_name}")
        # Verify the project is actually the project we are looking for
        if %x(git remote show origin | grep #{getCloneString(repo_owner, repo_name)}).empty?
            # Folder exists but is not the repository delete?

            puts "Folder for the project already exists within #{folder} would you like to delete it? (y/N)"
            answer = gets.chomp!

            if answer.downcase == "y"
                #Delete the folder               
                FileUtils.rm_rf("#{folder}#{repo_name}")

                # Clone it again
                verifyGitHubProject(folder, repo_owner, repo_name)
            else
                # Do not delete
                return false
            end
        else
            # Folder is a clone
            if %x(git status --porcelain | tr -d '??').empty?
                # Nothing is pending proceed
                return true
            else
                puts "The project has pending changes resolve them."
                return false
            end
        end
    end
    return true
end

repo_owner = nil
repo_name = nil

# Handle the command line arguemnts
if ARGV.size == 2
    # Repository owner and name have been provided

    repo_owner = ARGV[0]
    repo_name = ARGV[1]
elsif ARGV.size != 0
    # Invalid number of arguments
    puts "Invalid number of arguments provided expecting 0 or 2, received #{ARGV.size}"
end

#RESULTS_REGEX = /(FAILED|SUCCESS): \/([A-Za-z0-9 ]*)\/ ([A-Za-z0-9]*)([A-Za-z0-9 ]*)/

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

list = Array.new

# Set up either parsing a single repo or all stored repos.
if repo_owner && repo_name
    repo_id = Github_database.getRepoExist(con, repo_name, repo_owner)
    if repo_id
        list << [repo_id, repo_name, repo_owner]
    else
        puts "Repository #{repo_owner}/#{repo_name} has not been parsed!"
        Kernel.exit(false)
    end
else
    list = Github_database.getRepos(con)
end

list.each do |repo_id, repo_name, repo_owner|

    progress_indicator.puts "#{repo_owner}/#{repo_name}"
    if !verifyGitHubProject(project_dir, repo_owner, repo_name)
        Kernel.exit(false)
    end
    
    previous_result = Array.new

    csv_parser.setup_repo(repo_owner, repo_name)

    # Get the last commit metrics were calculate 
    last_commit = csv_parser.getLastCommit
    date = nil

    if last_commit && !last_commit.empty?
        date = last_commit[0][Metrics_database::DATE]
    end

    commits = Github_database.getCommitsByDate(con, repo_name, repo_owner, date)

    if commits.length == 0
        progress_indicator.puts "#{repo_owner}/#{repo_name} is already complete."
    end

    progress_indicator.total_length = commits.length

    commits.each do |commit|

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

                line.scan(Regexp.new("([A-Za-z0-9 ]+)_#{commit[Github_database::SHA]}")).each do |project|

                    # Set the value to the only value within the selection
                    project = project[0]
                    
                    # For some reason acra project is parsing its own as well as CrashReports values
                    # Might be for some reason when it fails 
                    val = "Project #{project} in version #{commit[Github_database::SHA]}"

                    # Store the results in the database
                    csv_parser.handle_all(project, commit[Github_database::SHA], commit[Github_database::DATE], output_dir)          

                    val += " succeed"

                    previous_result << "#{val}"
                end
            end
        else
            previous_result << "Failed to find any projects!"
        end
    end
end
