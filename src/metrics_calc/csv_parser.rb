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
require_relative '../database/metrics_interface'
require_relative '../progress/progress'

class CSVParser

    attr_accessor :repo_owner, :repo_name, :repo_id

    def initialize
        @con = Metrics_database.createConnection
    end

    def getLastCommit

        # Ensure repo and owner name are set
        if @repo_id
            return Metrics_database.getLastCommit(@con, @repo_id)
        end

        return nil
    end

    def setup_repo(repo_owner, repo_name)
        @repo_owner = repo_owner
        @repo_name = repo_name

        @repo_id = Metrics_database.getRepoExist(@con, @repo_name, @repo_owner)

        if @repo_id == nil
            @repo_id = Metrics_database.insertRepo(@con, @repo_name, @repo_owner)
        end
    end

    def handle_all(project_name, project_version, commit_date, output_dir)
        TYPES.each do |type|
            eval "handle_#{type.to_s}(project_name, project_version, commit_date, output_dir)"
        end
    end

    TYPES = [:method, :class, :package]
    EXTENTION = "csv"

    FILE_FLAG = 'r'

    METHOD_ORDER = ['name', 'number_method_line', 'nested_block_depth', 'cyclomatic_complexity', 'number_parameter']

    CLASS_ORDER = ['name', 'overridden_methods', 'attribute_count', 'children_count', 'method_count', 'inheritance_depth', 'lack_cohesion_method', 'specialization_index', 'static_method_count', 'weighted_methods', 'static_attribute_count']

    PACKAGE_ORDER = ['name', 'classes_number', 'afferent_coupling', 'interfaces_number', 'instability', 'efferent_coupling', 'abstractness', 'normalized_distance']

    # create define_type(project_name, project_version, commit_date, output_dir)
    TYPES.each do |type|
        define_method("handle_#{type.to_s}") do |project_name, project_version, commit_date, output_dir|
            
            file_location = "#{output_dir}#{project_name}_#{project_version}_metrics_#{type.to_s}.#{EXTENTION}"

            valid_file = true
            begin
                file = File.open(file_location, FILE_FLAG)
            rescue Errno::ENOENT => e
                valid_file = false
            end

            if valid_file
                commit_id = Metrics_database.getCommitExist(@con, project_version)
                
                if commit_id == nil
                    commit_id = Metrics_database.insertCommits(@con, @repo_id, project_name, project_version, commit_date)
                end

                not_first = nil
                file.each do |line|
                
                    if not_first
                        #call the correct parse method
                        eval "parse_#{type.to_s}(line, commit_id)"
                    else
                        not_first = true
                    end
                end

                file.close()
            end
        end
    end

private

    TYPES.each do |type|
        define_method("parse_#{type.to_s}") do |line, commit_reference|

            eval "Metrics_database.insert#{type.to_s.capitalize}(@con, commit_reference, '#{line.split(/,/).join("','")}')"
        end
    end
end

=begin

progress_indicator = Progress.new("CSV Manual Parsing")

output_dir = "/home/joseph/source_code/GitHubMining/acra_metrics/"
con = Github_database.createConnection

csv_parser = CSVParser.new

Github_database.getRepos(con).each do |repo_id, repo_name, repo_owner|

    csv_parser.setup_repo(repo_owner, repo_name)

    commits = Github_database.getCommitsByDate(con, repo_owner, repo_name)
    progress_indicator.total_length = commits.length

    commits.each do |commit|

        file = %x(ls #{output_dir}*#{commit[Github_database::SHA]}_metrics_class.csv)

        file.each_line do |line|

            project_name = line.scan(Regexp.new("(.*)/(.*)_#{commit[Github_database::SHA]}"))[0][1]

            progress_indicator.percentComplete(["Repository = #{repo_owner}/#{repo_name}", "Current commit = #{commit[Github_database::SHA]}", "Project name = #{project_name}"])

            csv_parser.handle_all(project_name, commit[Github_database::SHA], commit[Github_database::DATE], output_dir)
        end
    end

    Kernel.exit(true)
end
=end

#csv_parser.handle_method('acra', '0a61f9ebe96286a9a8e6cdee4a6d8b80d2971c43', '2012-12-07 04:52:38', '/home/joseph/source_code/GitHubMining/acra_metrics/')

#csv_parser.handle_class('acra', '0a61f9ebe96286a9a8e6cdee4a6d8b80d2971c43', '2012-12-07 04:52:38', '/home/joseph/source_code/GitHubMining/acra_metrics/')

#csv_parser.handle_package('acra', '0a61f9ebe96286a9a8e6cdee4a6d8b80d2971c43', '2012-12-07 04:52:38', '/home/joseph/source_code/GitHubMining/acra_metrics/')

=begin
METHOD
number_method_line INTEGER,         # MLOC 1
nested_block_depth INTEGER,         # NBD  2
cyclomatic_complexity INTEGER,      # VG   3
number_parameters INTEGER,          # PAR  4

Class
inheritance_depth INTEGER,          # DIT  5
weighted_methods INTEGER,           # WMC  9
children_count INTEGER,             # NSC  3
overridden_methods INTEGER,         # NORM 1
lack_cohesion_methods DOUBLE,       # LCOM 6
attribute_count INTEGER,            # NOF  2
static_attribute_count INTEGER,     # NSF  10
method_count   INTEGER,             # NOM  4
static_method_count INTEGER,        # NSM  8
specialization_index DOUBLE,        # SIX  7

Package
afferent_coupling INTEGER,          # CA   2
efferent_coupling INTEGER,          # CE   5
instability DOUBLE,                 # RMI  4
abstractness DOUBLE,                # RMA  7
normalized_distance DOUBLE,         # RMD  6
classes_number INTEGER,             # NOC  1
interfaces_number INTEGER,          # NOI  3
=end