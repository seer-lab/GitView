require_relative 'database_interface'

#The expression to match the given extention
EXTENTION_EXPRESSION = '%\.'

PYTHON = 'py'

def getFiles(con, extention)
    pick = con.prepare("SELECT #{FILE} FROM #{FILE} AS f INNER JOIN #{COMMITS} AS c ON f.#{COMMIT_REFERENCE} = c.#{COMMIT_ID} INNER JOIN #{REPO} AS r ON c.#{REPO_REFERENCE} = r.#{REPO_ID} WHERE #{NAME} LIKE ?")
    pick.execute("#{EXTENTION_EXPRESSION}#{extention}")

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end

def getPatches(con, commit_id, extention)
    pick = con.prepare("SELECT #{NAME}, #{PATCH} FROM #{FILE} WHERE #{COMMIT_REFERENCE} = ? AND #{NAME} LIKE ?")
    pick.execute(commit_id, "#{EXTENTION_EXPRESSION}#{extention}")

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end

con = createConnection()
patches = getPatches(con, 412, PYTHON)

#Can be negative*
numOfCommentsPerCommit = 0
numOfCodesPerCommit = 0

patches.each { |patch|
    #The first element is the file name
    patch[1] += "\n"
    comments = patch[1].scan(/(\+|-)(.*?(#.*)|(""".*"""))\n/)

    code = patch[1].scan(/(\+|-|(@@))(.*?)\n/)

    comments.each { |comment|
        # at [0] is whether the line is an addition or deletion
        # The whole line is at [1]
        # Only the comment is at either [2] (if it is a # comment) or [3] if it
        # is a multi-line comment
        #comment[0]

        if comment[0] == '-'
            #Deletion
            numOfCommentsPerCommit -= 1
        elsif comment[0] == '+'
            #Addition
            numOfCommentsPerCommit += 1
        elsif comment[0] == '@@'
            #Ignore
        end
    }

    code.each { |line|

        # Need to remove lines that start with spaces but 
        # are only comments
        if line[0] == '-' || line[0] == '+'

            if !line[2].match(/^\s*#(.*)/)

                if line[0] == '-'
                    #Deletion
                    numOfCodesPerCommit -= 1
                elsif line[0] == '-' || line[0] == '+'
                    #Addition
                    numOfCodesPerCommit += 1
                end
            end

        elsif line[0] == '@@'
            #Ignore
        end
    }
}

#if !code[1][2].match(/^\s*#(.*)/)
#    puts "yolo"
#else
#    puts "nolo"
#end
    

puts "commits = #{numOfCommentsPerCommit}"
puts "code = #{numOfCodesPerCommit}"
#patches[3][1].scan(/(\+|-)(.*?(#.*)|(""".*"""))\n/)
#patches[3][1].scan(/(\+|-|(@@))(.*?)\n/)

#patches[0][0].scan(/(#(.*)\n)|("""(.*)"""\n)/)

#a = "        # Lookup in cache and return if existing..."
#b = "        if k not in cls.__insts:"
#c = "        pass # default impl"
=begin
con = createConnection()

#Get the first line of documentation
files = getFiles(con, PYTHON)

totalNumberOfLinesofDocumentation = 0
totalNumberOfLinesOfCode = 0

#Pythonic comment regular expression
files.each { |file| 

    totalNumberOfLinesOfCode+=file[0].size
    comments = file[0].scan(/(#(.*)\n)|("""(.*)"""\n)/)

    comments.each { |comment|
        #Since there is 4 selection groups check if the second one is valid
        if comment[1] != nil
            puts comment[1]
            totalNumberOfLinesofDocumentation+=1
        #If the second selction is not valid the 3 one is the next choice
        elsif comment[3] != nil
            puts comment[3]
            totalNumberOfLinesofDocumentation+=1
        end
    }
}

totalNumberOfLinesOfSourceCode = totalNumberOfLinesOfCode - totalNumberOfLinesofDocumentation

(totalNumberOfLinesofDocumentation/totalNumberOfLinesOfCode.to_f)*100

=end


#length = files[0][0].size

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
