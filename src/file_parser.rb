require_relative 'database_interface'
require_relative 'regex'
require_relative 'stats_db_interface'
require_relative 'matchLines'
require_relative 'manage_quotes'
require_relative 'method_finder'

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

class LineCounter
    def initialize()
        @singleLineComment = 0
        @inLineSingle = 0
        @inLineMulti = 0
        @multiLineCommentInLine = 0
        @multiLineComment = 0
        @linesOfCode = 0
    end

    def singleLineComment(value)
        @singleLineComment+=value        
    end

    def inLineSingle(value)
        @inLineSingle +=value        
    end

    def inLineMulti(value)
        @inLineMulti +=value        
    end

    def multiLineCommentInLine(value)
        @multiLineCommentInLine += value
    end

    def multiLineComment(value)
        @multiLineComment+=value     
    end

    def linesOfCode(value)
        @linesOfCode+=value
    end
end

class CodeChurn
    def initialize()
        @commentAdded = 0
        @commentDeleted = 0
        @commentModified = 0
        @codeAdded = 0
        @codeDeleted = 0
        @codeModified = 0
    end

    def commentAdded(value)
        @commentAdded+=value        
    end

    def commentDeleted(value)
        @commentDeleted +=value        
    end

    def commentModified(value)
        @commentModified +=value       
    end

    def codeAdded(value)
        @codeAdded +=value        
    end

    def codeDeleted(value)
        @codeDeleted += value
    end

    def codeModified(value)
        @codeModified += value
    end
end

class Linker
    def initialize()
        @comment = Array.new
        @source_code = Array.new
    end

    def push()
        pushComment()
        pushSourceCode()
    end

    def pushComment()
        @comment.push("")
    end

    def pushSourceCode()
        @source_code.push("")
    end

    def setComment(comment)
        @comment[@comment.size-1] += comment
    end

    def setSourceCode(source_code)
        @source_code[@source_code.size-1] += source_code
    end

    def getComment()
        @comment[@comment.size-1]
    end

    def getSourceCode()
        @source_code[@source_code.size-1]
    end
end


# Identifies lines that have been added, deleted (and soon modified)
# Also the line is classified as a comment or code. 
# Note: the regular expression to identify comments and code require that the code
# is changed (eg. removing the blocks of quoted text) inorder to be accurate
def findMultiLineComments (lines)
    multiLine = false
    lineCounter = LineCounter.new
    codeLines = Array.new
    codeChurn = CodeChurn.new
    grouped = Linker.new
    commentLookingForMultiChild = false
    commentLookingForChild = false

    quoteManager = ManageQuotes.new

    method_finder = MethodFinder.new(lines)

    #linesModified = Array.new
    linesStreak = Hash.new
    linesStreak["-"] = Array.new
    linesStreak["+"] = Array.new
    linesCommentStreak = Hash.new
    linesCommentStreak["-"] = Array.new
    linesCommentStreak["+"] = Array.new
    patchNegStreak = 0
    patchPosStreak = 0
    patchPosPrev = 0
    patchNegPrev = 0
    totalCode = 0
    totalComment = 0

    lineCount = 0

    #puts patches
    #puts lines[0]
    #puts ""
    lines.each { |line|
        #Create a new grouping

        patchPosPrev = patchPosStreak
        patchNegPrev = patchNegStreak

        if !commentLookingForChild && !commentLookingForMultiChild
            grouped.push
        end

        quoteLessLine = quoteManager.removeQuotes(line[0])

        if $test
            puts "line = #{line[0]}"
            #puts "quot = #{quoteLessLine}"
            #puts "open = #{quoteManager.prevQuote}"
            #puts "multi = #{multiLine}"
            #puts ""
        end

        # Identify if the current line is a method
        if method_finder.methodFinderManager(lineCount)
            # Find length of the method
            m_end = method_finder.methodEndFinder(lineCount+method_finder.delta+1)

            if $test
                puts "lines length = #{lines.length}"
                puts "m_end = #{m_end}"
                #puts lines[lineCount..lineCount+2]
                puts "###### method_start #{lineCount} ######"
                puts lines[lineCount..m_end]
                puts "####### method_end #{m_end} #######"
            end

            #Lines contained by the method lines[lineCount..m_end]
        end

        if multiLine

            # A mutli-line comment has started but not finished. Check if it has ended.

            #TODO handle code proceeding the end of the multi-line comment
            result = quoteLessLine.scan(JAVA_MULTI_LINE_SECOND_HALF)[0]
            if result == nil
                #Still part of the multi-line, terminating line has not be found
                result = line

                #Can remove empty comment lines
                #if line[0].gsub(/\*/, '').match(/^\s*$/) == nil
                lineCounter.multiLineComment(1)
                
                #puts "part of multi"
            else
                #Found multi-line terminator
                multiLine = false

                #Can remove empty ending line
                #if result[0].gsub(/[\*\/]/, '').match(/^\s*$/) == nil
                lineCounter.multiLineComment(1)
                #puts "end of multi"
            end
            
            if line[0][0] == "+"
                patchPosStreak += 1
                #puts "patch add streak #{patchPosStreak}"
                linesCommentStreak["+"].push(line[0][1..-1])
                
                totalComment+=1
                codeChurn.commentAdded(1)
            elsif line[0][0] == "-"
                patchNegStreak += 1
                #puts "patch neg streak #{patchNegStreak}"
                linesCommentStreak["-"].push(line[0][1..-1])

                totalComment-=1
                codeChurn.commentDeleted(1)
            end
            
            #Set the grouping to the comment
            grouped.setComment("\n#{result[0]}")
            #comments[index] += "\n#{result[0]}"
        else
            # Check for whether there is a comment in the given line

            #Remove the quotes prior to checking it
            result = quoteLessLine.scan(JAVA_MULTI_LINE_FULL)
            
            result = result[0]
            if result != nil

                comment = nil
                # A full comment is in the line
                if result[1] != nil || result[2] != nil

                    # Determine whether the line was added or deleted
                    if line[0][0] == "+"
                        patchPosStreak += 1
                        #puts "patch add streak #{patchPosStreak}"
                        linesCommentStreak["+"].push(line[0][1..-1])
                        codeChurn.commentAdded(1)
                        totalComment+=1
                    elsif line[0][0] == "-"
                        patchNegStreak += 1
                        #puts "patch neg streak #{patchNegStreak}"
                        linesCommentStreak["-"].push(line[0][1..-1])
                        codeChurn.commentDeleted(1)
                        totalComment-=1
                    end
                    
                    # Single Comment 'In-line'
                    if result[1] != nil 
                        #lineCounter.singleLineComment(1)
                        comment = result[1]

                    # Multi Comment 'In-line'
                    elsif result[2] != nil
                        #lineCounter.multiLineCommentInLine(1)
                        comment = result[2]
                    end

                    # Check whether there is source code at the beginning or the end of the line.
                    if (result[3] != nil && result[3][1..-1] != nil && result[3][1..-1].match(WHITE_SPACE) == nil) || (result[0] != nil && result[0][1..-1] != nil && result[0][1..-1].match(WHITE_SPACE) == nil)

                        if line[0][0] == "+"
                            #patchPosStreak += 1
                            #puts "patch add streak #{patchPosStreak}"
                            linesStreak["+"].push(line[0][1..-1])
                            codeChurn.codeAdded(1)
                            totalCode+=1
                        elsif line[0][0] == "-"
                            #patchNegStreak += 1
                            #puts "patch neg streak #{patchNegStreak}"
                            linesStreak["-"].push(line[0][1..-1])
                            codeChurn.codeDeleted(1)
                            totalCode-=1
                        end
                        #Stop looking for the code                        
                        commentLookingForChild = false
                    end

                    # Add the comment to the list of comments
                    #comments.push(comment)
                end

            else

                # Check if it is the beginning of a multi-line comment

                #TODO handle multi-line comment starting on a line of code 
                result = quoteLessLine.scan(JAVA_MULTI_LINE_FIRST_HALF)
                if result[0] != nil
                    #There is a multi-line comment starting here
                    multiLine = true
                    #index = comments.size
                    #comments.push(result[0][0])
                    #lineCounter.multiLineComment(1)
                    if line[0][0] == "+"
                        patchPosStreak += 1
                        #puts "patch add streak #{patchPosStreak}"
                        linesCommentStreak["+"].push(line[0][1..-1])
                        codeChurn.commentAdded(1)
                        totalComment+=1
                    elsif line[0][0] == "-"
                        patchNegStreak += 1
                        #puts "patch neg streak #{patchNegStreak}"
                        linesCommentStreak["-"].push(line[0][1..-1])
                        codeChurn.commentDeleted(1)
                        totalComment-=1
                    end

                else
                    #There is no comment on this line handle is a purely code
                    
                    if line[0][0] == "+"
                        patchPosStreak += 1
                        #puts "patch add streak #{patchPosStreak}"
                        linesStreak["+"].push(line[0][1..-1])

                        if line[0].match(WHITE_SPACE) == nil && line[0][1..-1].match(WHITE_SPACE) == nil
                            codeChurn.codeAdded(1)
                            totalCode+=1
                        end
                    elsif line[0][0] == "-"
                        patchNegStreak += 1
                        #puts "patch neg streak #{patchNegStreak}"
                        linesStreak["-"].push(line[0][1..-1])
                        if line[0].match(WHITE_SPACE) == nil && line[0][1..-1].match(WHITE_SPACE) == nil
                            codeChurn.codeDeleted(1)
                            totalCode-=1
                        end
                    end

                    #codeLines.push(line[0])
                    
                    if commentLookingForChild
                        #Code found store it in the grouping
                        #grouped.setSourceCode(line[0])
                        #Stop looking for the code
                        commentLookingForChild = false

                    end
                    
                end
            end
        end

        if patchNegStreak > 0 && patchPosStreak > 0
            #puts "neg #{patchNegStreak}"
            #puts "pos #{patchPosStreak}"
            if patchNegPrev == patchNegStreak && patchPosPrev == patchPosStreak
                
                if $test || $log
                    #puts "streak over"

                    puts "Code Modified:"
                    linesStreak["-"].each { |negLine|
                        puts "- #{negLine}"
                    }
                    linesStreak["+"].each { |posLine|
                        puts "+ #{posLine}"
                    }

                    puts "Comment Modified:"
                    linesCommentStreak["-"].each { |negLine|
                        puts "- #{negLine}"
                    }
                    linesCommentStreak["+"].each { |posLine|
                        puts "+ #{posLine}"
                    }
                end

                # Please Note:
                # Code modifications may be influenced by the comments being modified
                # As well as comment modifications being influenced by the code being modified
                # Example:
                # - System.out.println("Hello World!"); //This line tells the world hello really loud
                # + System.out.println("Hello World!"); //This prints out Hello World
                # Currently this will show up as a modificiation for both code and comment
                codeMod = Hash.new
                commentMod = Hash.new
                codeModLength = 0
                
                code_pid = Thread.new do
                    codeMod = findShortestDistance(linesStreak["+"], linesStreak["-"], $high_threshold, $low_threshold, $size_threshold, $ONE_TO_MANY)

                    found = Hash.new
                    codeMod.each {|i,v|
                        v.each {|k, d|
                            if found[k] ==nil
                                found[k] = true
                            end
                        }
                    }
                    codeModLength = found.length
                end

                #comment_pid = fork do
                commentMod = findShortestDistance(linesCommentStreak["+"], linesCommentStreak["-"], $high_threshold, $low_threshold, $size_threshold, $ONE_TO_MANY)
                #end

                found = Hash.new
                commentMod.each {|i,v|
                    v.each {|k, d|
                        if found[k] ==nil
                            found[k] = true
                        end
                    }
                }
                commentModLength = found.length

                # Wait for the results
                code_pid.join
                #Process.wait code_pid
                #Process.wait comment_pid

                #codeModLength = codeMod.length
                #commentModLength = commentMod.length
                
                if $test || $log
                    codeMod.each { |n, v|
                        v.each{ |p, d|
                            puts "PosLine = #{linesStreak["+"][p]} => NegLine = #{linesStreak["-"][n]} => distance = #{d}"
                        }
                    }

                    commentMod.each { |n, v|
                        v.each{ |p, d|
                            puts "PosLine = #{linesCommentStreak["+"][p]} => NegLine = #{linesCommentStreak["-"][n]} => distance = #{d}"
                        }
                    }

                    puts "Number of calc code modifications #{codeModLength}"
                    puts "Number of calc comment modifications #{commentModLength}"
                end

                codeChurn.codeModified(codeMod.length)
                codeChurn.commentModified(commentMod.length)

                #comments added = comments added - # of positive lines modified
                codeChurn.commentAdded((-1)*commentModLength)
                #comments deleted = comments deleted - # of lines modified(since the mapping is 1 Negative to many Positve lines)
                codeChurn.commentDeleted((-1)*commentMod.length)

                codeChurn.codeAdded((-1)*codeModLength)
                codeChurn.codeDeleted((-1)*codeMod.length)

                #puts "mods = #{mods}"
                #patchNegStreak, patchPosStreak = 0, 0

                # Reset arrays 
                #linesStreak["+"] = Array.new
                #linesStreak["-"] = Array.new
                #linesCommentStreak["+"] = Array.new
                #linesCommentStreak["-"] = Array.new

                #a = $stdin.gets 
            end
            
        end

        if patchNegStreak > 0 || patchPosStreak > 0
            #puts "neg #{patchNegStreak}"
            #puts "pos #{patchPosStreak}"
            if patchNegPrev == patchNegStreak && patchPosPrev == patchPosStreak
                patchNegStreak, patchPosStreak = 0, 0

                # Reset arrays 
                linesStreak["+"] = Array.new
                linesStreak["-"] = Array.new
                linesCommentStreak["+"] = Array.new
                linesCommentStreak["-"] = Array.new
            end
        end
        #puts "Comment #{grouped.getComment}"
        #puts "Code #{grouped.getSourceCode}"
        #puts ""
        #puts "in line single #{lineCounter.inLineSingle(0)}"
        #puts "in line multi #{lineCounter.inLineMulti(0)}"
        #puts "single #{lineCounter.singleLineComment(0)}"
        #puts "multiInline = #{lineCounter.multiLineCommentInLine(0)}"
        #puts "multi #{lineCounter.multiLineComment(0)}"
        #puts "code #{lineCounter.linesOfCode(0)}"

        #puts "commentAdded = #{codeChurn.commentAdded(0)}"
        #puts "commentDeleted = #{codeChurn.commentDeleted(0)}"
        #puts "codeAdded = #{codeChurn.codeAdded(0)}"
        #puts "codeDeleted = #{codeChurn.codeDeleted(0)}"
        #puts ""
        
        #a = $stdin.gets
        lineCount += 1
        method_finder.iterate
    }
    return [[totalComment, totalCode], codeLines, lineCounter, codeChurn]
end

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

    comments = findMultiLineComments(lines)

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
