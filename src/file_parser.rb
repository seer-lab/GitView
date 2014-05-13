require_relative 'database_interface'
require_relative 'regex'
require_relative 'stats_db_interface'
require_relative 'matchLines'
require_relative 'manage_quotes'
require_relative 'method_finder'
require_relative 'code_parser'

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

# Set the output file to the given parameter
$stdout.reopen(outputFile, "a")
$stderr.reopen(outputFile, "a")

def mergePatch(lines, patch, name)

    if patch != nil && !lines[0][0].match(/^\d\d\d.*?/)

        # A file that does not have a new line at the end will have
        # '\ No newline at end of file' at the very end

        if $test_merge
            puts "#{patch}"
        end

        patch = patch.gsub(NEWLINE_FIXER,"\n")
        #flag = false
        #if patch.match(/\\ No newline at end of file\n.+/)
        #    puts "no new line!"
        #    a = gets
        #    flag = true
        #end
        patches = patch.scan(PATCH_EXPR)

        #patch = patch.gsub(NEWLINE_FIXER,"\n")
        #patchlines = patch.scan(LINE_EXPR)


        currentLine = 0

        #if lines.size == patches.size
        #    puts true
        #else 
        #    puts false
        #end

        deletions = 0
        #begin
        a = ''
    
        patches.each { |patchLine|
            #begin
            
                if $test_merge
                    puts "#{patchLine}"
                    #puts "patchDiff #{patchlines}"

                    puts "currentLine = #{currentLine}"
                    puts "line #{lines[currentLine]}"

                    #if lines[currentLine].class == Array
                    #    puts "line #{lines[currentLine][0]}"
                    #else
                        
                    #end
                end

                if patchLine[0] == "+"
                    #Addition
                    #puts "addition"
                    #line should be in file
                    lines[currentLine][0] =  "+" +  lines[currentLine][0]
                    currentLine+=1
                elsif patchLine[0] == "-"
                    #Deletion
                    #puts "deletion"
                    #line should not be in the file.
                    lines.insert(currentLine, ["-" + patchLine[2]])
                    deletions += 1
                    currentLine+=1
                elsif patchLine[0] == "@@"
                    #Patch start
                    #puts "patch start"
                    patchOffset = patchLine[2].scan(PATCH_LINE_NUM)

                    check = patchLine[2].scan(PATCH_LINE_NUM_OLD)
                
                    if $test_merge
                        if check[0] == nil
                            #Handle bad patch
                            puts "check #{check}"
                            #a = gets
                        end
                    end
                    #puts "patchoffset #{patchOffset}"
                    #puts "lines #{lines}"
                    lines, currentLine = fillBefore(lines, patchOffset[0][3].to_i-1 + deletions, currentLine)
                    deletions = 0
                else
                    if patchLine[0] == nil && patchLine[2] == "\\ No newline at end of file" 
		    elsif patchLine[0] == nil && patchLine[2] == ""

                    else 
                        #Context
                        #puts "context"
                        #Do nothing since the lines of code should alreay be there.
                        currentLine+=1
                    end
                end

                if $test_merge
                    #puts lines[currentLine-1][0]
                    #a = gets

                    #puts lines[0]
                    puts "deletions #{deletions}"
                    puts ""
                end
        }
    elsif patch == nil
        if $test_merge
            # Patch is empty
            puts "nothing in patch!?"
        end
    else 
    	$NOT_FOUND += 1
        $BAD_FILE_ARRAY.push([lines, patch])
    	if $test_merge
    	    puts "File request error"
    	    puts "This has happened #{$NOT_FOUND}"

            puts patch != nil
            puts !lines[0][0].match(/^\d\d\d.*?/)
            puts lines[0][0].scan(/^\d\d\d(.+)/)
    	    a = $stdin.gets
    	end
    end
    
    return lines
end

# TODO document
def fillBefore (lines, offset, currentLine)

    while offset > currentLine do
        # Start setting the lines to empty
        lines[currentLine][0] = " " + lines[currentLine][0]
        currentLine+=1
    end

    return lines, currentLine
end

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

files = Github_database.getFileForParsing(con, JAVA, repo_name, repo_owner)

if !$test
    repo_id = Stats_db.getRepoId(stats_con, repo_name, repo_owner)
end

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

prev_commit = files[0][2]
current_commit = 0
commit_comments = 0
commit_code = 0

commit_id = nil

churn = Hash.new()
churn["CommentAdded"] = 0
churn["CommentDeleted"] = 0
churn["CommentModified"] = 0
churn["CodeAdded"] = 0
churn["CodeDeleted"] = 0
churn["CodeModified"] = 0
churn["TotalComment"] = 0
churn["TotalCode"] = 0

fileHashTable = Hash.new

codeParser = CodeParser.new($test, $log, $high_threshold, $low_threshold, $size_threshold, $ONE_TO_MANY)

#Map file name to the array of stats about that file.
files.each { |file, file_name, current_commit_id, date, body, patch, com_name, aut_name|
    #file = files[0][0]
    
    current_commit = current_commit_id

    if $test
        puts "file: #{file_name}"
        #a = gets
    end

    if file[-1] != "\n"
        file += "\n"
    end

    lines = file.scan(LINE_EXPR)

    lines = mergePatch(lines, patch, file_name)
    #pass the lines of code and the related patch

    comments = codeParser.findMultiLineComments(lines)

    churn["CommentAdded"] += comments[3].commentAdded(0)
    churn["CommentDeleted"] += comments[3].commentDeleted(0)
    churn["CommentModified"] += comments[3].commentModified(0)
    churn["CodeAdded"] += comments[3].codeAdded(0)
    churn["CodeDeleted"] += comments[3].codeDeleted(0)
    churn["CodeModified"] += comments[3].codeModified(0)

    churn["TotalComment"] += comments[0][0]
    churn["TotalCode"] += comments[0][1]

    if $test
        puts comments[0][0] #The total number of lines of comments in the file
        puts comments[0][1] #The total number of lines of code in the file
    end

    sum = comments[3].commentAdded(0) + comments[3].commentDeleted(0) + comments[3].codeAdded(0) + comments[3].codeDeleted(0) + comments[3].commentModified(0)  + comments[3].codeModified(0)
    #Get the path and the name of the file.
    package, name = parsePackages(file_name)
    
    if !$test && sum > 0
        
        if commit_id == nil

            committer_id = Stats_db.getUserId(stats_con, com_name)
            author_id = Stats_db.getUserId(stats_con, com_name)

            commit_id = Stats_db.insertCommit(stats_con, repo_id, date, body, churn["TotalComment"], churn["TotalCode"], churn["CommentAdded"], churn["CommentDeleted"], churn["CommentModified"], churn["CodeAdded"], churn["CodeDeleted"], churn["CodeModified"], committer_id, author_id)
        end
        Stats_db.insertFile(stats_con, commit_id, package, name, comments[0][0], comments[0][1], comments[3].commentAdded(0), comments[3].commentDeleted(0), comments[3].commentModified(0), comments[3].codeAdded(0), comments[3].codeDeleted(0), comments[3].codeModified(0))
    end
    
    if prev_commit != current_commit
        #puts "finished commit"
        prev_commit = current_commit

        if !$test && sum > 0
            Stats_db.updateCommit(stats_con, commit_id, churn["TotalComment"], churn["TotalCode"], churn["CommentAdded"], churn["CommentDeleted"], churn["CommentModified"], churn["CodeAdded"], churn["CodeDeleted"], churn["CodeModified"])
        end
        commit_id = nil
        churn["CommentAdded"] = 0
        churn["CommentDeleted"] = 0
        churn["CommentModified"] = 0
        churn["CodeAdded"] = 0
        churn["CodeDeleted"] = 0        
        churn["CodeModified"] = 0
        churn["TotalComment"] = 0
        churn["TotalCode"] = 0
        #commit_comments = 0
        #commit_code = 0
    end
}

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
