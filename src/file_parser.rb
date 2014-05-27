require_relative 'database_interface'
require_relative 'regex'
require_relative 'stats_db_interface'
require_relative 'matchLines'
require_relative 'manage_quotes'

require_relative 'code_parser'
require_relative 'merger'
require_relative 'progress'

# Possible reasons for negative files
# - Files that could not be retreived (404/403 etc)
# - Files that are renamed (path is adjusted)

$NOT_FOUND = 0

$BAD_FILE_ARRAY = Array.new

#Command line arguements in order (default $test to true)
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

progress_indicator = Progress.new

# Set the output file to the given parameter
$stdout.reopen(outputFile, "a")
$stderr.reopen(outputFile, "a")

# Parse the path of each file for their package.
# Return the package and the file name (with extention)
def parsePackages(path)
    package = path.scan(PACKAGE_PARSER)
    #puts "name #{path}"
    #puts "package #{package[0]}"
    #a = gets
    return package[0]
end

def mergeThreshold(threshold)
    threshold = ((threshold.to_f*10).to_i).to_s
    if threshold.length == 1 
        threshold = "0#{threshold}"
    end
    return threshold
end

con = Github_database.createConnection()

stats_con = Stats_db.createConnectionThreshold("#{$size_threshold.to_s}_#{mergeThreshold($low_threshold)}_#{mergeThreshold($high_threshold)}", $ONE_TO_MANY)

progress_indicator.puts "Loading Files..."
files = Github_database.getFileForParsing(con, JAVA, repo_name, repo_owner)

if !$test
    repo_id = Stats_db.getRepoId(stats_con, repo_name, repo_owner)
end

# Set the progress indicator's max value
progress_indicator.total_length = files.length

progress_indicator.puts "Loading Tags..."
tags = Github_database.getTags(con, repo_name, repo_owner)

tags.each { |sha, tag_name, tag_desc, tag_date|
    if !$test
        Stats_db.insertTag(stats_con, repo_id, sha, tag_name, tag_desc, tag_date)
    elsif $test_tag
        puts "sha = #{sha}"
        puts "tag_name = #{tag_name}"
        puts "tag_desc = #{tag_desc}"
        puts "tag_date = #{tag_date}"
    end
}

fileCount = 0

prev_commit = files[0][2]
current_commit = 0
commit_comments = 0
commit_code = 0

commit_id = nil

METRICS = ["CommentAdded", "CommentDeleted", "CommentModified", "CodeAdded", "CodeDeleted", "CodeModified", "TotalComment", "TotalCode"]

churn = Hash.new

METRICS.each do |metric|
    churn[metric] = 0
end

fileHashTable = Hash.new

merger = Merger.new($test_merge)

codeParser = CodeParser.new($test, $log, $high_threshold, $low_threshold, $size_threshold, $ONE_TO_MANY)

#Map file name to the array of stats about that file.
files.each do |file, file_name, current_commit_id, date, body, patch, com_name, aut_name|
    #file = files[0][0]
    progress_indicator.percentComplete(file_name)

    current_commit = current_commit_id

    if $test
        puts "file: #{file_name}"
        #a = gets
    end

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
        puts comments[0][0] #The total number of lines of comments in the file
        puts comments[0][1] #The total number of lines of code in the file
        puts "method_churn = #{method_churn}"
        puts "method_statement_churn = #{method_statement_churn}"
    end

    sum = comments[1].commentAdded(0) + comments[1].commentDeleted(0) + comments[1].codeAdded(0) + comments[1].codeDeleted(0) + comments[1].commentModified(0)  + comments[1].codeModified(0)
    #Get the path and the name of the file.
    package, name = parsePackages(file_name)
    
    if !$test && sum > 0
        
        if commit_id == nil

            committer_id = Stats_db.getUserId(stats_con, com_name)
            author_id = Stats_db.getUserId(stats_con, com_name)

            commit_id = Stats_db.insertCommit(stats_con, repo_id, date, body, churn["TotalComment"], churn["TotalCode"], churn["CommentAdded"], churn["CommentDeleted"], churn["CommentModified"], churn["CodeAdded"], churn["CodeDeleted"], churn["CodeModified"], committer_id, author_id)
        end
        file_id = Stats_db.insertFile(stats_con, commit_id, package, name, comments[0][0], comments[0][1], comments[1].commentAdded(0), comments[1].commentDeleted(0), comments[1].commentModified(0), comments[1].codeAdded(0), comments[1].codeDeleted(0), comments[1].codeModified(0))

        # Insert the method churn count
        Stats_db.insertMethod(stats_con, file_id, method_churn)

        # Insert the method statement churn count
        Stats_db.insertMethodStatement(stats_con, file_id, method_statement_churn)
    end
    
    if prev_commit != current_commit
        #puts "finished commit"
        prev_commit = current_commit

        if !$test && sum > 0
            Stats_db.updateCommit(stats_con, commit_id, churn["TotalComment"], churn["TotalCode"], churn["CommentAdded"], churn["CommentDeleted"], churn["CommentModified"], churn["CodeAdded"], churn["CodeDeleted"], churn["CodeModified"])
        end
        commit_id = nil

        METRICS.each do |metric|
            churn[metric] = 0
        end
    end
    
    fileCount+=1
end

progress_indicator.percentComplete(nil)
puts "filesize = #{files.length}"
#puts "Bad files count #{$NOT_FOUND}"
#puts ""

#$BAD_FILE_ARRAY.each { |info|

#    info.each { |elements|
#        a = $stdin.gets 
#        puts elements
#        puts ""
#    }
    
#}

#puts "hash table = #{fileHashTable}"
