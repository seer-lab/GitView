require_relative 'database_interface'
require_relative 'regex'
require_relative 'stats_db_interface'

# Possible reasons for negative files
# - Files that could not be retreived (404/403 etc)
# - Files that are renamed (path is adjusted)

$NOT_FOUND = 0

$BAD_FILE_ARRAY = Array.new

#Command line arguements in order (default $test to true)
repo_owner, repo_name, $test = "", "", true

if ARGV.size == 3
	repo_owner, repo_name = ARGV[0], ARGV[1]
	
	if ARGV[2] == "false"
		$test = false
	end
else
	abort("Invalid parameters")
end

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
        @codeAdded = 0
        @codeDeleted = 0
    end

    def commentAdded(value)
        @commentAdded+=value        
    end

    def commentDeleted(value)
        @commentDeleted +=value        
    end

    def codeAdded(value)
        @codeAdded +=value        
    end

    def codeDeleted(value)
        @codeDeleted += value
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

def findMultiLineComments (lines)
    multiLine = false
    index = 0
    lineCounter = LineCounter.new
    comments = Array.new
    codeLines = Array.new
    codeChurn = CodeChurn.new
    grouped = Linker.new
    commentLookingForMultiChild = false
    commentLookingForChild = false

    linesModified = Array.new
    patchNegStreak = 0
    patchPosStreak = 0
    patchPosPrev = 0
    patchNegPrev = 0


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

        puts line[0]
        #puts ""

        if multiLine
            result = line[0].scan(JAVA_MULTI_LINE_SECOND_HALF)[0]
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
                puts "patch add streak #{patchPosStreak}"
                codeChurn.commentAdded(1)
            elsif line[0][0] == "-"
                patchNegStreak += 1
                puts "patch neg streak #{patchNegStreak}"
                codeChurn.commentDeleted(1)
            end

            #puts "X#{result[0]}X"
            #puts "Here #{comments[index]}"
            
            #Set the grouping to the comment
            grouped.setComment("\n#{result[0]}")
            comments[index] += "\n#{result[0]}"
        else
            #Java
            result = line[0].scan(JAVA_MULTI_LINE_FULL)
            
            result = result[0]
            if result != nil
                #$0 is whether it is addition or deletion
                #$1 is single line comment
                #$2 is multi-line comment
                #$3 is the code after the comment
                
                comment = nil
                if result[1] != nil || result[2] != nil

                    if line[0][0] == "+"
                        patchPosStreak += 1
                        puts "patch add streak #{patchPosStreak}"
                        codeChurn.commentAdded(1)
                    elsif line[0][0] == "-"
                        patchNegStreak += 1
                        puts "patch neg streak #{patchNegStreak}"
                        codeChurn.commentDeleted(1)
                    end
                    
                    if result[1] != nil # Single Comment 'In-line'
                        lineCounter.singleLineComment(1)
                        comment = result[1]
                        
                        #Set the grouping to the comment
                        if commentLookingForChild
                            grouped.setComment("\n#{comment}")
                        else
                            grouped.setComment("#{comment}")
                        end
                        
                        #Start looking for the code that this comment is talking about
                        commentLookingForChild = true

                        #puts "In Line Single"
                    elsif result[2] != nil # Multi Comment 'In-line'
                        lineCounter.multiLineCommentInLine(1)
                        comment = result[2]
                        #puts "In Line Multi"

                        #Set the grouping to the comment
                        if commentLookingForChild
                            grouped.setComment("\n#{comment}")
                        else
                            grouped.setComment("#{comment}")
                        end
                        #Start looking for the code that this comment is talking about
                        commentLookingForChild = true        
                    end

                    if result[0] != nil && result[0].match(WHITE_SPACE) == nil
                        #puts "with Source code"
                        if result[1] != nil # Signle inline comment that has source code prior to it
                            lineCounter.inLineSingle(1)
                            
                            #Code found store it in the grouping
                            grouped.setSourceCode(result[0])
                            #Stop looking for the code
                            commentLookingForChild = false
                        elsif result[2] != nil # Multi inline comment that has source code prior to it
                            lineCounter.inLineMulti(1)

                            #Code found store it in the grouping
                            grouped.setSourceCode(result[1])
                            #Stop looking for the code
                            commentLookingForChild = false
                        end
                        # CommentInline with code
                        lineCounter.linesOfCode(1)
                        codeLines.push(result[0])
                    end

                    if result[3] != nil && result[3].match(WHITE_SPACE) == nil
                        if line[0][0] == "+"
                            patchPosStreak += 1
                            puts "patch add streak #{patchPosStreak}"
                            codeChurn.codeAdded(1)
                        elsif line[0][0] == "-"
                            patchNegStreak += 1
                            puts "patch neg streak #{patchNegStreak}"
                            codeChurn.codeDeleted(1)
                        end

                        if result[2] != nil # Multi inline comment that has source code prior to it
                            lineCounter.inLineMulti(1)
                        end
                        #Code found store it in the grouping
                        grouped.setSourceCode(result[3])
                        #Stop looking for the code
                        commentLookingForChild = false
                    end

                    # Add the comment to the list of comments
                    comments.push(comment)
                end

            else

                #Check for part of multi line comment
                result = line[0].scan(JAVA_MULTI_LINE_FIRST_HALF)
                if result[0] != nil
                    #There is a multi-line comment starting here
                    multiLine = true
                    index = comments.size
                    comments.push(result[0][0])
                    lineCounter.multiLineComment(1)

                    if line[0][0] == "+"
                        patchPosStreak += 1
                        puts "patch add streak #{patchPosStreak}"
                        codeChurn.commentAdded(1)
                    elsif line[0][0] == "-"
                        patchNegStreak += 1
                        puts "patch neg streak #{patchNegStreak}"
                        codeChurn.commentDeleted(1)
                    end

                    #Set the grouping to the comment
                    grouped.setComment(result[0][0])
                    #Start looking for the code that this comment is talking about
                    commentLookingForMultiChild = true
                    #puts "multi line "
                else

                    if line[0].match(WHITE_SPACE) == nil

                        #puts "codes if nothing else"
                        #This line is not a comment
                        lineCounter.linesOfCode(1)

                        if line[0][0] == "+"
                            patchPosStreak += 1
                            puts "patch add streak #{patchPosStreak}"
                            codeChurn.codeAdded(1)
                        elsif line[0][0] == "-"
                            patchNegStreak += 1
                            puts "patch neg streak #{patchNegStreak}"
                            codeChurn.codeDeleted(1)
                        end

                        codeLines.push(line[0])
                        
                        if commentLookingForChild
                            #Code found store it in the grouping
                            grouped.setSourceCode(line[0])
                            #Stop looking for the code
                            commentLookingForChild = false

                        elsif commentLookingForMultiChild

                            #Remove strings 
                            #statements = line[0].gsub(/\".*?\"/, '')

                            # Check if it is a single line terminator
                            result = line[0].scan(JAVA_CODE_LINE_BLOCK)

                            commentLookingForMultiChild = false

                            if result[0] == nil
                                result = line[0].scan(JAVA_CODE_BLOCK)
                                
                                if result[0] == nil
                                    result = line[0].scan(JAVA_CODE_TERMINATOR)
                                   
                                    if result[0] == nil
                                        result = line
                                        commentLookingForMultiChild = true
                                    end
                                else
                                    commentLookingForMultiChild = true
                                end
                            end
                            
                            grouped.setSourceCode("\n#{result[0]}")                            

                        end
                    end
                end
            end
        end

        if patchNegStreak > 0 || patchPosStreak > 0
            if patchNegPrev == patchNegStreak && patchPosPrev == patchPosStreak
                puts "streak over"

                if patchPosStreak > 0 && patchNegStreak > 0
                    if patchPosStreak >= patchNegStreak
                        linesModified = patchNegStreak
                    else
                        linesModified = patchPosStreak
                    end
                else
                    linesModified = 0
                end

                puts "Number of modifications #{linesModified}"
                patchNegStreak, patchPosStreak = 0, 0
            end
            #a = $stdin.gets 
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

        
        #a = gets
    }
    return [comments, codeLines, lineCounter, codeChurn]
end

def mergePatch(lines, patch, name)

    if patch != nil && !lines[0][0].match(/\d\d\d.*?/)

        # A file that does not have a new line at the end will have
        # '\ No newline at end of file' at the very end

        if $test
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
            
                if $test
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
                    #TODO remove carrage return from patch
                    lines.insert(currentLine, ["-" + patchLine[2]])
                    deletions += 1
                #if lines[currentLine].class == Array
                #    puts "Is an array"
                #    a = gets
                #    puts "lines = #{lines[currentLine]}"
                #    a = gets
                #end
                    currentLine+=1
                elsif patchLine[0] == "@@"
                    #Patch start
                    #puts "patch start"
                    patchOffset = patchLine[2].scan(PATCH_LINE_NUM)

                    check = patchLine[2].scan(PATCH_LINE_NUM_OLD)
                
                
                    if $test
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

                    #while deletions > 0 
                    #    lines[currentLine][0] = " " + lines[currentLine][0]
                    #    currentLine+=1
                    #    deletions -= 1
                    #end
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

                if $test
                    #puts lines[currentLine-1][0]
                    #a = gets

                    #puts lines[0]
                    puts "deletions #{deletions}"
                    puts ""
                end
=begin
            rescue Exception => e
                puts e
                a = gets
                puts "patchstart\n#{patch}\npatchend"

                lines.each { |line| 
                    puts line
                    a = gets
                }
                a = gets
                puts "flag #{flag}"
                puts "deletions = #{deletions}"
                puts "currentLine = #{currentLine}"
                puts "patchlines #{patches.length}"
                #a = gets

                puts "lines #{lines.length}"
                a = gets
                

                puts "name #{name}"
                a = gets
            end
=end
            #if lines[currentLine-1][0] == patchLine[2]
            #    if a != "s" 
            #        a = gets.chomp!
            #   end
            #end
        }
    elsif patch == nil
        if $test
            # Patch is empty
            puts "nothing in patch!?"
        end
    else 
    	$NOT_FOUND += 1
        $BAD_FILE_ARRAY.push([lines, patch])
    	if $test
    	    puts "File request error"
    	    puts "This has happened #{$NOT_FOUND}"

            puts patch != nil
            puts !lines[0][0].match(/\d\d\d.*?/)
    	    a = $stdin.gets
    	end
    end


#    file = ""
    # TODO make apart of the main loop (divide iterations in half)
#    lines.each{ |line|
#        file += "#{line}\n"
#   }

    return lines
end

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


def getFile(con, extension, repo_name, repo_owner)
    pick = con.prepare("SELECT f.#{Github_database::FILE}, f.#{Github_database::NAME}, c.#{Github_database::COMMIT_ID}, com.#{Github_database::DATE}, c.#{Github_database::BODY}, f.#{Github_database::PATCH} FROM #{Github_database::FILE} AS f INNER JOIN #{Github_database::COMMITS} AS c ON f.#{Github_database::COMMIT_REFERENCE} = c.#{Github_database::COMMIT_ID} INNER JOIN #{Github_database::REPO} AS r ON c.#{Github_database::REPO_REFERENCE} = r.#{Github_database::REPO_ID} INNER JOIN #{Github_database::USERS} AS com ON c.#{Github_database::COMMITER_REFERENCE} = com.#{Github_database::USER_ID} WHERE r.#{Github_database::REPO_NAME} LIKE ? AND r.#{Github_database::REPO_OWNER} LIKE ? AND f.#{Github_database::NAME} LIKE ? ORDER BY com.#{Github_database::DATE}")
    pick.execute(repo_name, repo_owner, "#{Github_database::EXTENSION_EXPRESSION}#{extension}")

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end

con = Github_database.createConnection()
stats_con = Stats_db.createConnection()

#username, repo_name = 'nostra13', 'Android-Universal-Image-Loader'
#username, repo_name = 'SpringSource', 'spring-framework'
#username, repo_name = 'elasticsearch', 'elasticsearch'
#username, repo_name = 'ACRA', 'acra'
#username, repo_name = 'junit-team', 'junit'
#files = getFile(con, PYTHON, 'luigi', 'spotify')
#files = getFile(con, JAVA, 'SlidingMenu', 'jfeinstein10')
files = getFile(con, JAVA, repo_name, repo_owner)

if !$test
    repo_id = Stats_db.getRepoId(stats_con, repo_name, repo_owner)
end

prev_commit = files[0][2]
current_commit = 0
commit_comments = 0
commit_code = 0

commit_id = nil

churn = Hash.new()
churn["CommentAdded"] = 0
churn["CommentDeleted"] = 0
churn["CodeAdded"] = 0
churn["CodeDeleted"] = 0

fileHashTable = Hash.new

#Map file name to the array of stats about that file.
files.each { |file|
    #file = files[0][0]

    
    
    current_commit = file[2]

    if $test
        puts "file: #{file[1]}"
        #a = gets
    end

    size = file[0].size

    if file[0][size-1] != "\n"
        file[0] += "\n"
    end

    lines = file[0].scan(LINE_EXPR)

    lines = mergePatch(lines, file[5], file[1])
    #pass the lines of code and the related patch

    comments = findMultiLineComments(lines)

    churn["CommentAdded"] += comments[3].commentAdded(0)
    churn["CommentDeleted"] += comments[3].commentDeleted(0)
    churn["CodeAdded"] += comments[3].codeAdded(0)
    churn["CodeDeleted"] += comments[3].codeDeleted(0)

    #puts "CommentAdded = #{churn["CommentAdded"]}"
    #puts "CommentDeleted = #{churn["CommentDeleted"]}"
    #puts "CodeAdded = #{churn["CodeAdded"]}"
    #puts "CodeDeleted = #{churn["CodeDeleted"]}"

    #Get the path and the name of the file.
    package, name = parsePackages(file[1])
    if !$test && (comments[3].commentAdded(0) + comments[3].commentDeleted(0) + comments[3].codeAdded(0) + comments[3].codeDeleted(0)) > 0
        
        if commit_id == nil
            commit_id = Stats_db.insertCommit(stats_con, repo_id, file[3], file[4], churn["CommentAdded"], churn["CommentDeleted"], churn["CodeAdded"], churn["CodeDeleted"])
        end
        Stats_db.insertFile(stats_con, commit_id, package, name, comments[3].commentAdded(0), comments[3].commentDeleted(0), comments[3].codeAdded(0), comments[3].codeDeleted(0))
    end
    
    if prev_commit != current_commit
        #puts "finished commit"
        prev_commit = current_commit

        if !$test && (comments[3].commentAdded(0) + comments[3].commentDeleted(0) + comments[3].codeAdded(0) + comments[3].codeDeleted(0)) > 0
            Stats_db.updateCommit(stats_con, commit_id, churn["CommentAdded"], churn["CommentDeleted"], churn["CodeAdded"], churn["CodeDeleted"])
        end
        commit_id = nil
        churn["CommentAdded"] = 0
        churn["CommentDeleted"] = 0
        churn["CodeAdded"] = 0
        churn["CodeDeleted"] = 0 
        #commit_comments = 0
        #commit_code = 0
    end

    #a = gets
=begin
   comments = findMultiLineComments(lines, file[5])

    if fileHashTable[file[1]] == nil
        fileHashTable[file[1]] = Array.new().push(comments)
    else
        fileHashTable[file[1]].push(comments)
    end
    fileComments = comments[2].singleLineComment(0)+ comments[2].multiLineCommentInLine(0) + comments[2].multiLineComment(0)
    fileCode = comments[2].linesOfCode(0)

    Stats_db.insertFile(stats_con, commit_id, file[1], fileComments, fileCode)

    puts "Total file comments = #{fileComments}"
    puts "Total file code = #{fileCode}"

    commit_comments += fileComments
    commit_code += fileCode
    
    

    #puts file[1]
    #puts "Comments: #{comments[0]}"
    #puts ""
    #puts "Code: #{comments[1]}"
    #puts ""
    #puts "in line single #{comments[2].inLineSingle(0)}"
    #puts "in line multi #{comments[2].inLineMulti(0)}"
    #puts "single #{comments[2].singleLineComment(0)}"
    #puts "multiInline = #{comments[2].multiLineCommentInLine(0)}"
    #puts "multi #{comments[2].multiLineComment(0)}"
    #puts "code #{comments[2].linesOfCode(0)}"
    puts ""
=end
}

puts "Bad files count #{$NOT_FOUND}"
puts ""

$BAD_FILE_ARRAY.each { |info|

    info.each { |elements|
        a = $stdin.gets 
        puts elements
        puts ""
    }
    
}

#puts "hash table = #{fileHashTable}"
