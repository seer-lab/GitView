require_relative 'database_interface'

# The neccessary regular expressions for python multi-line comments
PYTHON_MULTI_LINE_FULL = /(.*?)(#.*)|(""".*""")/

PYTHON_MULTI_LINE_FIRST_HALF = /"""(.*)/

PYTHON_MULTI_LINE_SECOND_HALF = /(.*)"""/

JAVA_MULTI_LINE_FULL = /(.*?)(\/\/.*)|((\/\*.*\*\/)(.*))/

JAVA_MULTI_LINE_FIRST_HALF = /\/\*(.*)/

JAVA_MULTI_LINE_SECOND_HALF = /(.*)\*\//

RUBY_MULTI_LIKE_FULL = /(.*?)(#.*)/

RUBY_MULTI_LINE_FIRST_HALF = /=being (.*)/

RUBY_MULTI_LINE_SECOND_HALF = /^=end/

WHITE_SPACE = /^\s*$/

LINE_EXPR = /(.*?)\n/

PYTHON = 'py'

RUBY = 'rb'

JAVA = 'java'

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


# For now I am not handling 2 multi line comments on the same line they will be
# treaded as 1
# Pass it the lines of the file that have been determined to be additions or deletions
def findMultiLineComments (lines)
    multiLine = false
    comments = Array.new
    index = 0
    lineCounter = LineCounter.new
    codeLines = Array.new
    grouped = Linker.new
    commentLookingForChild = false

    lines.each { |line|
        #Create a new grouping
        if !commentLookingForChild
            grouped.push
        end

        #puts line[0]
        #a = gets
        if multiLine
            result = line[0].scan(JAVA_MULTI_LINE_SECOND_HALF)[0]
            if result == nil
                #Still part of the multi-line, terminating line has not be found
                result = line
                lineCounter.multiLineComment(1)
                #puts "part of multi"
            else
                #Found multi-line terminator
                multiLine = false
                lineCounter.multiLineComment(1)
                #puts "end of multi"
            end
            #puts "X#{result[0]}X"
            #puts "Here #{comments[index]}" 
            comments[index] += "\n#{result[0]}"
        else
            #Python
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
                        grouped.setComment(comment)
                        #Start looking for the code that this comment is talking about
                        commentLookingForChild = true

                        #puts "In Line Single"
                    elsif result[2] != nil # Multi Comment 'In-line'
                        lineCounter.multiLineCommentInLine(1)
                        comment = result[2]
                        #puts "In Line Multi"            
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

                #TODO handle when some one starts a multi-line comment on a line that has source code
                #OR when some one ends a mutli-line comment and has source code preceeding it. (on the same line)
                #Check for part of multi line comment
                result = line[0].scan(JAVA_MULTI_LINE_FIRST_HALF)
                if result[0] != nil
                    #There is a multi-line comment starting here
                    multiLine = true
                    index = comments.size
                    comments.push(result[0][0])
                    lineCounter.multiLineComment(1)
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
                        end
                    end
                end
            end
        end
        puts "Comment #{grouped.getComment}"
        puts "Code #{grouped.getSourceCode}"
        a = gets
    }


    return [comments, codeLines, lineCounter]
end

# For now I am not handling 2 multi line comments on the same line they will be
# treaded as 1
# Pass it the lines of the file that have been determined to be additions or deletions
def findMultiLineCommentsPython (lines)
    multiLine = false
    comments = Array.new
    index = 0
    lineCounter = LineCounter.new
    codeLines = Array.new
    grouped = Linker.new
    commentLookingForChild = false

    lines.each { |line|
        #Create a new grouping
        if !commentLookingForChild
            grouped.push
        end

        #puts line[0]
        #a = gets
        if multiLine
            result = line[0].scan(PYTHON_MULTI_LINE_SECOND_HALF)[0]
            if result == nil
                #Still part of the multi-line, terminating line has not be found
                result = line
                lineCounter.multiLineComment(1)
                #puts "part of multi"
            else
                #Found multi-line terminator
                multiLine = false
                lineCounter.multiLineComment(1)
                #puts "end of multi"
            end
            #puts "X#{result[0]}X"
            #puts "Here #{comments[index]}" 
            comments[index] += "\n#{result[0]}"
        else
            #Python
            result = line[0].scan(PYTHON_MULTI_LINE_FULL)

            result = result[0]
            if result != nil

                #The first element with contain the comment if it is a in-line comment
                #The second element will contain the comment if it is a multi-line comment
                comment = nil
                if result[1] != nil || result[2] != nil

                    if result[1] != nil # Single Comment 'In-line'
                        lineCounter.singleLineComment(1)
                        comment = result[1]
                        #Set the grouping to the comment
                        grouped.setComment(comment)
                        #Start looking for the code that this comment is talking about
                        commentLookingForChild = true

                        #puts "In Line Single"
                    elsif result[2] != nil # Multi Comment 'In-line'
                        lineCounter.multiLineCommentInLine(1)
                        comment = result[2]
                        #puts "In Line Multi"            
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
                        end
                        # CommentInline with code
                        lineCounter.linesOfCode(1)
                        codeLines.push(result[0])
                    end

                    # Add the comment to the list of comments
                    comments.push(comment)
                end

            else

                #TODO add support for inline commenting with multi-line comments
                #Check for part of multi line comment
                result = line[0].scan(PYTHON_MULTI_LINE_FIRST_HALF)
                if result[0] != nil
                    #There is a multi-line comment starting here
                    multiLine = true
                    index = comments.size
                    comments.push(result[0][0])
                    lineCounter.multiLineComment(1)
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
                        end
                    end
                end
            end
        end
        puts "Comment #{grouped.getComment}"
        puts "Code #{grouped.getSourceCode}"
        a = gets
    }


    return [comments, codeLines, lineCounter]
end

def findMultiLineCommentsLink (lines)
    multiLine = false
    comments = Array.new
    index = 0
    lineCounter = LineCounter.new
    codeLines = Array.new

    lines.each { |line|
        #puts line[0]
        #a = gets
        if multiLine
            result = line[0].scan(PYTHON_MULTI_LINE_SECOND_HALF)[0]
            if result == nil
                #Still part of the multi-line, terminating line has not be found
                result = line
                lineCounter.multiLineComment(1)
                #puts "part of multi"
            else
                #Found multi-line terminator
                multiLine = false
                lineCounter.multiLineComment(1)
                #puts "end of multi"
            end
            #puts "X#{result[0]}X"
            #puts "Here #{comments[index]}" 
            comments[index] += "\n#{result[0]}"
        else
            #Python
            result = line[0].scan(PYTHON_MULTI_LINE_FULL)

            result = result[0]
            if result != nil

                #The first element with contain the comment if it is a in-line comment
                #The second element will contain the comment if it is a multi-line comment
                comment = nil
                if result[1] != nil || result[2] != nil
                    if result[1] != nil
                        lineCounter.singleLineComment(1)
                        comment = result[1]
                        #puts "In Line Single"
                    elsif result[2] != nil
                        lineCounter.multiLineCommentInLine(1)
                        comment = result[2]
                        #puts "In Line Multi"            
                    end

                    if result[0] != nil && result[0].match(WHITE_SPACE) == nil
                        #puts "with Source code"
                        if result[1] != nil
                            lineCounter.inLineSingle(1)
                        elsif result[2] != nil
                            lineCounter.inLineMulti(1)
                        end
                        # CommentInline with code
                        lineCounter.linesOfCode(1)
                        codeLines.push(result[0])
                    end

                    # Add the comment to the list of comments
                    comments.push(comment)
                end

            else

                #TODO add support for inline commenting with multi-line comments
                #Check for part of multi line comment
                result = line[0].scan(PYTHON_MULTI_LINE_FIRST_HALF)
                if result[0] != nil
                    #There is a multi-line comment starting here
                    multiLine = true
                    index = comments.size
                    comments.push(result[0][0])
                    lineCounter.multiLineComment(1)
                    #puts "multi line "
                else

                    if line[0].match(WHITE_SPACE) == nil

                        #puts "codes if nothing else"
                        #This line is not a comment
                        lineCounter.linesOfCode(1)
                        codeLines.push(line[0])
                    end
                end
            end
        end
    }
    return [comments, codeLines, lineCounter]
end


def getFile(con, extension, repo_name, repo_owner)
    pick = con.prepare("SELECT f.#{FILE}, f.#{NAME} FROM #{FILE} AS f INNER JOIN #{COMMITS} AS c ON f.#{COMMIT_REFERENCE} = c.#{COMMIT_ID} INNER JOIN #{REPO} AS r ON c.#{REPO_REFERENCE} = r.#{REPO_ID} INNER JOIN #{USERS} AS com ON c.#{COMMITER_REFERENCE} = com.#{USER_ID} WHERE r.#{REPO_NAME} LIKE ? AND r.#{REPO_OWNER} LIKE ? AND f.#{NAME} LIKE ? ORDER BY com.#{DATE}")
    pick.execute(repo_name, repo_owner, "#{EXTENSION_EXPRESSION}#{extension}")

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end


con = createConnection()

#files = getFile(con, PYTHON, 'luigi', 'spotify')
#files = getFile(con, JAVA, 'SlidingMenu', 'jfeinstein10')
files = getFile(con, JAVA, 'Android-Universal-Image-Loader', 'nostra13')

fileHashTable = Hash.new

#Map file name to the array of stats about that file.
files.each { |file|
    #file = files[0][0]

    size = file[0].size

    if file[0][size-1] != "\n"
        file[0] += "\n"
    end

    lines = file[0].scan(LINE_EXPR)

    comments = findMultiLineComments(lines)

    if fileHashTable[file[1]] == nil
        fileHashTable[file[1]] = Array.new().push(comments)
    else
        fileHashTable[file[1]].push(comments)
    end

    puts file[1]
    puts "Comments: #{comments[0]}"
    puts ""
    puts "Code: #{comments[1]}"
    puts ""
    puts "in line single #{comments[2].inLineSingle(0)}"
    puts "in line multi #{comments[2].inLineMulti(0)}"
    puts "single #{comments[2].singleLineComment(0)}"
    puts "multiInline = #{comments[2].multiLineCommentInLine(0)}"
    puts "multi #{comments[2].multiLineComment(0)}"
    puts "code #{comments[2].linesOfCode(0)}"
    puts ""
}

#puts "hash table = #{fileHashTable}"



#puts metric(comments)


#length = files[0][0].size

=begin
def parseComments(file)
    inComment = false
    singleLine = false
    length = files[0][0].size
    while i < length

        if !inComment && files[0][0][i] == '#'
            inComment = true
            singleLine = true
        elsif files[0][0][i] == '\n'
            if i+1 < length 
                if files[0][0][i+1] == '#'
                    #Still part of comment block
                elsif files[0][0][i+1..i+4] == '"""'
                    #Still part of comment block
                else
                    inComment = false
                    #Search for next comment
                    #all stuff between is part of code at that level (only stop adding code to that level when a new comment is found at that level.)
                end
            end
        end
        i = i + 1
    end
end
=end