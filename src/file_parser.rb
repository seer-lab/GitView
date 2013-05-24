require_relative 'database_interface'

EXTENSION_EXPRESSION = '%\.'

LINE_EXPR = /(.*?)\n/

PYTHON = 'py'

RUBY = 'rb'
#TODO remove dangling comment
# For now I am not handling 2 multi line comments on the same line they will be
# treaded as 1
# Pass it the lines of the file that have been determined to be additions or deletions
def findMultiLineComments (lines)
    multiLine = false
    comments = Array.new
    index = 0

    lines.each { |line|

        if multiLine
            result = line[0].scan(/(.*)"""/)[0]
            if result == nil
                #puts "still multi"
                result = line[0].scan(/(.*)/)[0]
                #Still multi-line, terminating line has not be found
            else
                #Found multi-line terminator
                multiLine = false
            end
            #puts "X#{result[0]}X"
            #puts "Here #{comments[index]}" 
            comments[index] += "\n#{result[0]}"
        else
            #Python
            result = line[0].scan(/"""(.*)"""/)

            #Ruby
            #result = line.scan(/=begin(.*)(end)?/)

            #Java/C(++)
            #result = line.scan(/\/\*(.*)(\*\/)?/)

            result = result[0]
            if(result != nil)
                if result[1] != nil && result[0] == nil
                    #single line finish
                    #puts "single line multi_line"
                end

                # Add the comment to the list of comments
                comments.push(result[0])
            else
                #Check for part of multi line comment
                result = line[0].scan(/"""(.*)/)
                if result[0] != nil
                    multiLine = true
                    index = comments.size
                    comments.push(result[0][0])
                else
                    #This line is not a comment
                    #puts "#{line} is not a comment!"
                end
            end
        end
    }

    # Remove the dangling comment
    if multiLine
        comments.pop
    end
    
    comments
end


def getFile(con, extension)
    pick = con.prepare("SELECT f.#{FILE} FROM #{FILE} AS f INNER JOIN #{COMMITS} AS c ON f.#{COMMIT_REFERENCE} = c.#{COMMIT_ID} INNER JOIN #{REPO} AS r ON c.#{REPO_REFERENCE} = r.#{REPO_ID} WHERE f.#{NAME} LIKE ? LIMIT 1")
    pick.execute("#{EXTENSION_EXPRESSION}#{extension}")

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end

    con = createConnection()

files = getFile(con, PYTHON)

file = files[0][0]

size = files.size

if file[size-1] != "\n"
    file += "\n"
end

lines = file.scan(LINE_EXPR)

comments = findMultiLineComments(lines)

puts comments


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