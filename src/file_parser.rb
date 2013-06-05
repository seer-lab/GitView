require_relative 'database_interface'
require_relative 'regex'
require_relative 'stats_db_interface'



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

def findMultiLineComments (lines, patch)
    multiLine = false
    index = 0
    lineCounter = LineCounter.new
    comments = Array.new
    codeLines = Array.new
    codeChurn = CodeChurn.new
    grouped = Linker.new
    commentLookingForMultiChild = false
    commentLookingForChild = false

    #puts patches
    #puts lines[0]

    lines.each { |line|
        #Create a new grouping

        if !commentLookingForChild && !commentLookingForMultiChild
            grouped.push
        end

        #puts line[0]
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
                codeChurn.commentAdded(1)
            elsif line[0][0] == "-"
                codeChurn.commentDeleted()
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
                #$0 is code before comment
                #$1 is single line comment
                #$2 is multi-line comment
                #$3 is the code after the comment
                
                comment = nil
                if result[1] != nil || result[2] != nil

                    if line[0][0] == "+"
                        codeChurn.commentAdded(1)
                    elsif line[0][0] == "-"
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
                            codeChurn.codeAdded(1)
                        elsif line[0][0] == "-"
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
                        codeChurn.commentAdded(1)
                    elsif line[0][0] == "-"
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
                            codeChurn.codeAdded(1)
                        elsif line[0][0] == "-"
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
        #puts "Comment #{grouped.getComment}"
        #puts "Code #{grouped.getSourceCode}"
        #puts ""
        #puts "in line single #{lineCounter.inLineSingle(0)}"
        #puts "in line multi #{lineCounter.inLineMulti(0)}"
        #puts "single #{lineCounter.singleLineComment(0)}"
        #puts "multiInline = #{lineCounter.multiLineCommentInLine(0)}"
        #puts "multi #{lineCounter.multiLineComment(0)}"
        #puts "code #{lineCounter.linesOfCode(0)}"
        puts ""
        a = gets
    }
    return [comments, codeLines, lineCounter]
end

def mergePatch(lines, patch)

    patches = patch.scan(PATCH_EXPR)

    currentLine = 0

    #Parsing patches:
    # Break up into patch lines (easy enough)
        # Lines starting with '@@' are patch blocks (block is up til next @@ or end of patch)
        # Lines starting with '+'/'-'\s are addition and deletion lines
        # Lines with no special symbol are context lines
    # Identify what block the additions and deletions are apart of
        # based on how it is implemented... (see below)
    #Continue on next patch item
    
#Could go through patches and identify where the comments code blocks are (with line numbers)
#I would then need to always go back to the previous patch as well, to get the object and then update the object accordingly
#OR
#Could go through patches but base it off the original file
#This would allow for the code churn to be calculated at any point but would
#For both of these options however the ability to identify multiline comments that are added to a existing mutli-line comment (more than 3 to 6 lines (based on how it is parsed))
#Since 3 lines of context before and after are given.
    patches.each { |patchLine|

        puts "#{patchLine}"

        #line = patchLine[0].scan(PATCH_EXPR)
        puts "currentLine = #{currentLine}"
        puts "line #{lines[currentLine]}"

        if patchLine[0] == "+"
            #Addition
            puts "addition"
            #line should be in file
            lines[currentLine][0] =  "+" +  lines[currentLine][0]
            currentLine+=1
        elsif patchLine[0] == "-"
            #Deletion
            puts "deletion"
            #
            lines.insert(currentLine, ["-" + patchLine[2]])
            currentLine+=1
        elsif patchLine[0] == "@@"
            #Patch start
            puts "patch start"
            patchOffset = patchLine[2].scan(PATCH_LINE_NUM)
            puts "#{patchOffset}"
            lines, currentLine = fillBefore(lines, patchOffset[0][2].to_i-1, currentLine)
        else
            #Context
            puts "context"
            #Do nothing since the lines of code should alreay be there.
            currentLine+=1
        end
        puts lines[currentLine-1][0]

        #puts lines[0]
        #puts ""
        a = gets
    }

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


# For now I am not handling 2 multi line comments on the same line they will be
# treaded as 1
# Pass it the lines of the file that have been determined to be additions or deletions
def findMultiLineCommentsTotal (lines)
    multiLine = false
    index = 0
    lineCounter = LineCounter.new
    comments = Array.new
    codeLines = Array.new
    grouped = Linker.new
    commentLookingForMultiChild = false
    commentLookingForChild = false

    lines.each { |line|
        #Create a new grouping
        if !commentLookingForChild && !commentLookingForMultiChild
            grouped.push
        end

        #puts line[0]
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
                #$0 is code before comment
                #$1 is single line comment
                #$2 is multi-line comment
                #$3 is the code after the comment
                
                comment = nil
                if result[1] != nil || result[2] != nil

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
        #puts "Comment #{grouped.getComment}"
        #puts "Code #{grouped.getSourceCode}"
        #puts ""
        #puts "in line single #{lineCounter.inLineSingle(0)}"
        #puts "in line multi #{lineCounter.inLineMulti(0)}"
        #puts "single #{lineCounter.singleLineComment(0)}"
        #puts "multiInline = #{lineCounter.multiLineCommentInLine(0)}"
        #puts "multi #{lineCounter.multiLineComment(0)}"
        #puts "code #{lineCounter.linesOfCode(0)}"
        #puts ""
        #a = gets
    }


    return [comments, codeLines, lineCounter]
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

repo_name = 'Android-Universal-Image-Loader'
username = 'nostra13'
#files = getFile(con, PYTHON, 'luigi', 'spotify')
#files = getFile(con, JAVA, 'SlidingMenu', 'jfeinstein10')
files = getFile(con, JAVA, repo_name, username)

repo_id = Stats_db.getRepoId(stats_con, repo_name, username)

prev_commit = files[0][2]
current_commit = 0
commit_comments = 0
commit_code = 0

commit_id = nil

fileHashTable = Hash.new

#Map file name to the array of stats about that file.
files.each { |file|
    #file = files[0][0]

    if commit_id == nil
        commit_id = Stats_db.insertCommit(stats_con, repo_id, file[3], file[4], commit_comments, commit_code)
    end
    
    current_commit = file[2]
    puts "file: #{file[1]}"
    #a = gets

    size = file[0].size

    if file[0][size-1] != "\n"
        file[0] += "\n"
    end

    lines = file[0].scan(LINE_EXPR)

    file = mergePatch(lines, file[5])
    #pass the lines of code and the related patch
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
    
    if prev_commit != current_commit
        puts "finished commit"
        prev_commit = current_commit

        Stats_db.updateCommit(stats_con, commit_id, commit_comments, commit_code)
        commit_id = nil
        commit_comments = 0
        commit_code = 0
    end

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

#puts "hash table = #{fileHashTable}"