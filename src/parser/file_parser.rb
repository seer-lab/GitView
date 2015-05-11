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
require_relative '../regex'
require_relative '../database/stats_db_interface'
#require_relative 'match_lines'
#require_relative 'manage_quotes'

require_relative 'code_parser'
require_relative 'merger'
require_relative '../progress/progress'

# Possible reasons for negative files
# - Files that could not be retreived (404/403 etc)
# - Files that are renamed (path is adjusted)

project_title = "Project Analizer"

# Command line arguements
repo_owner, repo_name, $test, outputFile, $high_threshold, $ONE_TO_MANY = "", "", true, "", 0.5, true
$low_threshold, $size_threshold = 0.8, 20
$log = true
$test_merge = false
$test_tag = false

if ARGV.size == 8
	repo_owner, repo_name = ARGV[0], ARGV[1]
	
	if ARGV[2] == "false"
		$test = false
	end
    outputFile, $ONE_TO_MANY = ARGV[3], ARGV[4]

    $high_threshold, $low_threshold, $size_threshold = ARGV[5], ARGV[6], ARGV[7]
elsif ARGV.size == 4
    repo_owner, repo_name = ARGV[0], ARGV[1]
    
    if ARGV[2] == "false"
        $test = false
    end
    outputFile = ARGV[3]
else
	abort("Invalid parameters")
end

# Output that a test is underway.
if $test
    project_title = "#{project_title}\nTesting YES"
end

# Create the progress bar for the process
progress_indicator = Progress.new(project_title)

# Set the output file to the given parameter
$stdout.reopen(outputFile, "a")
$stderr.reopen(outputFile, "a")

def findLastCommit(con, owner, repo)

    repo_id = Stats_db.getRepoExist(con, repo, owner)

    if repo_id
        # Get the latest commit and look for it
        # *Note it is possible that the developers re-based their project
        # and the commit no longer exists, however this is unlikely 
        # and also this would prob. require a fresh mining
        return Stats_db.getLastCommit(con, repo_id)
    end
    return nil
end

# Parse the path of each file for their package.
# Return the package and the file name (with extention)
def parsePackages(path)
    return path.scan(PACKAGE_PARSER)[0]
end

con = Github_database.createConnection()

stats_con = Stats_db.createConnectionThreshold("#{$size_threshold.to_s}_#{Stats_db.mergeThreshold($low_threshold)}_#{Stats_db.mergeThreshold($high_threshold)}", $ONE_TO_MANY)

progress_indicator.puts "Loading Files..."

# Get the sha hash from the last commit
sha = findLastCommit(stats_con, repo_owner, repo_name)

files = Github_database.getFileForParsing(con, JAVA, repo_name, repo_owner, sha)

if !$test
    repo_id = Stats_db.getRepoId(stats_con, repo_name, repo_owner)
end

# Set the progress indicator's max value
progress_indicator.total_length = files.length

progress_indicator.puts "Loading Tags..."

if sha
    date = Stats_db.getLastTag(stats_con, repo_id)
    tags = Github_database.getNewestTags(con, repo_name, repo_owner, date)
else
    tags = Github_database.getTags(con, repo_name, repo_owner)
end

# Collect the tag information
tags.each { |sha, tag_name, tag_desc, tag_date, commit_sha|
    if !$test
        Stats_db.insertTag(stats_con, repo_id, sha, tag_name, tag_desc, tag_date, commit_sha)
    elsif $test_tag
        puts "sha = #{sha}"
        puts "tag_name = #{tag_name}"
        puts "tag_desc = #{tag_desc}"
        puts "tag_date = #{tag_date}"
        puts "commit_sha = #{commit_sha}"
    end
}

if files && files.length > 0
    fileCount = 0

    # Set the previous commit to the current sha hash
    prev_commit = files[0][1]
    commit_comments = 0
    commit_code = 0

    commit_id = nil

    METRICS = ["CommentAdded", "CommentDeleted", "CommentModified", "CodeAdded", "CodeDeleted", "CodeModified", "TotalComment", "TotalCode"]

    churn = Hash.new

    METRICS.each do |metric|
        churn[metric] = 0
    end

    merger = Merger.new($test_merge)

    codeParser = CodeParser.new($test, $log, $high_threshold, $low_threshold, $size_threshold, $ONE_TO_MANY)

    # Map file name to the array of stats about that file.
    files.each do |file, sha, file_name, current_commit_id, date, body, patch, com_name, aut_name|

        if !$test
            progress_indicator.percentComplete(["Working on Analizing Files...", "Current File: #{file_name}"])
        end

        if prev_commit != sha

            # The previous commit's files are finished set up the next commit
            prev_commit = sha
            commit_id = nil

            METRICS.each do |metric|
                churn[metric] = 0
            end
        end

        if $test
            puts "file: #{file_name}"
        end

        # Fix any file missing a ending new line
        if file[-1] != "\n"
            file += "\n"
        end

        lines = file.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').scan(LINE_EXPR)

        lines = merger.mergePatch(lines, patch)
        #pass the lines of code and the related patch

        comments = codeParser.findMultiLineComments(lines)

        method_churn = codeParser.methodCounter

        method_statement_churn = codeParser.statementCounter

        churn["CommentAdded"] += comments[1].commentAdded(0)
        churn["CommentDeleted"] += comments[1].commentDeleted(0)
        churn["CommentModified"] += comments[1].commentModified(0)
        churn["CodeAdded"] += comments[1].codeAdded(0)
        churn["CodeDeleted"] += comments[1].codeDeleted(0)
        churn["CodeModified"] += comments[1].codeModified(0)

        churn["TotalComment"] += comments[0][0]
        churn["TotalCode"] += comments[0][1]

        if $test
            progress_indicator.puts lines
            progress_indicator.puts churn
            progress_indicator.puts method_churn
            a = $stdin.gets

            puts "Total number of lines of comments = #{comments[0][0]}"
            puts "Total number of lines of code = #{comments[0][1]}"

            puts "method_churn = #{method_churn}"
            puts "method_statement_churn = #{method_statement_churn}"
        end

        sum = comments[1].commentAdded(0) + comments[1].commentDeleted(0) + comments[1].codeAdded(0) + comments[1].codeDeleted(0) + comments[1].commentModified(0)  + comments[1].codeModified(0)
        
        # Get the path and the name of the file.
        package, name = parsePackages(file_name)
        
        if !$test && sum > 0
            
            if commit_id == nil

                committer_id = Stats_db.getUserId(stats_con, com_name)
                author_id = Stats_db.getUserId(stats_con, com_name)

                commit_id = Stats_db.insertCommit(stats_con, repo_id, sha, date, body, churn["TotalComment"], churn["TotalCode"], churn["CommentAdded"], churn["CommentDeleted"], churn["CommentModified"], churn["CodeAdded"], churn["CodeDeleted"], churn["CodeModified"], committer_id, author_id)

            else
                Stats_db.updateCommit(stats_con, commit_id, churn["TotalComment"], churn["TotalCode"], churn["CommentAdded"], churn["CommentDeleted"], churn["CommentModified"], churn["CodeAdded"], churn["CodeDeleted"], churn["CodeModified"])
            end
            file_id = Stats_db.insertFile(stats_con, commit_id, package, name, comments[0][0], comments[0][1], comments[1].commentAdded(0), comments[1].commentDeleted(0), comments[1].commentModified(0), comments[1].codeAdded(0), comments[1].codeDeleted(0), comments[1].codeModified(0))

            # Insert the method churn count
            Stats_db.insertMethod(stats_con, file_id, method_churn)

            # Insert the method statement churn count
            Stats_db.insertMethodStatement(stats_con, file_id, method_statement_churn)
        end
        
        fileCount+=1
    end

    progress_indicator.percentComplete
    puts "filesize = #{files.length}"
end
