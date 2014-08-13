#require 'fileutils'
require_relative '../database/database_interface'
require_relative '../progress/progress'

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
output_dir = fixDir("~/source_code/GitHubMining/acra_metrics")
log_file = "~/source_code/GitHubMining/ant_build/"
log = true

metric_compiler = "~/source_code/GitHubMining/src/metrics_calc/metric_compiler"

progress_indicator = Progress.new(APP_TITLE)

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
            redirect = "2>&1 | tee #{log_file}#{repo_owner}_#{repo_name}_#{commit[Github_database::SHA][0..6]}_#{Time.now.to_s[0..-7].gsub(/\s/, '_').gsub(/:/, '-')}"
        end

        # Collect the information about the previous commit
        result = %x(bash #{metric_compiler} #{project_dir}#{repo_name}/ #{output_dir} #{commit[Github_database::SHA]} #{redirect})

        # search through results for errors or success
        results = result.scan(RESULTS_REGEX)

        if results && results.length > 0

            results.each do |element|

                val = "Project #{element[1]} in version #{element[2]}"

                if element[0] == 'SUCCESS'
                    # Completed successfully
                    val += " succeed"

                elsif element[0] == 'FAILED'
                    # Failed
                    val += " failed #{element[3]}"
                end
                previous_result << "#{val}"
            end
        else
            previous_result << "Failed to find any projects!"
        end
    end

    # Exit after the first project for testing purposes
    Kernel.exit(true)
end
 