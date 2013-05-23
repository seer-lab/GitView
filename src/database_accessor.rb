require 'gchart'
require_relative 'database_interface'

#The expression to match the given extention
EXTENTION_EXPRESSION = '%\.'

PYTHON = 'py'


class CodeChurn
    def initialize()
        @codeAddition = 0
        @codeDeletion = 0
        @commentAddition = 0
        @commentDeletion = 0
    end

    def codeAddition(value)
        @codeAddition += value
    end

    def codeDeletion(value)
        @codeDeletion += value
    end

    def commentAddition(value)
        @commentAddition += value
    end

    def commentDeletion(value)
        @commentDeletion += value
    end

    def totalCodes()
        @codeAddition - @codeDeletion   
    end
    def totalComments()
        @commentAddition - @commentDeletion
    end
end

class StatArray
    def initialize()
        @codeAddition = Array.new
        @codeDeletion =  Array.new 
        @commentAddition = Array.new
        @commentDeletion =  Array.new
    end

    def codeAdditionPush(value)
        @codeAddition.push(value)
    end

    def codeDeletionPush(value)
        @codeDeletion.push(value)
    end

    def commentAdditionPush(value)
        @commentAddition.push(value)
    end

    def commentDeletionPush(value)
        @commentDeletion.push(value)
    end

    def codeAddition()
        @codeAddition
    end

    def codeDeletion()
        @codeDeletion
    end

    def commentAddition()
        @commentAddition
    end

    def commentDeletion()
        @commentDeletion
    end
end

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

def getCommitIds(con, username, repo)
    pick = con.prepare("SELECT c.#{COMMIT_ID} FROM #{REPO} AS r INNER JOIN #{COMMITS} AS c ON r.#{REPO_ID} = c.#{REPO_REFERENCE} WHERE r.#{REPO_NAME} LIKE ? AND r.#{REPO_OWNER} LIKE ? LIMIT 290")

    pick.execute(repo, username)

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end

# Take the Array of +CodeChurn+ objects and create an array for each of the 
# different values.
def createStateArray(codeChurns)

    metricArray = StatArray.new
    codeChurns.each { |codeChurn|

        # Add the code additions to the list
        metricArray.codeAdditionPush(codeChurn.codeAddition(0))

        # Add the code deletions to the list
        metricArray.codeDeletionPush(codeChurn.codeDeletion(0))

        # Add the comment addition to the list
        metricArray.commentAdditionPush(codeChurn.commentAddition(0))

        # Add the comment deletions to the list
        metricArray.commentDeletionPush(codeChurn.commentDeletion(0))
    }
    return metricArray
end


#have the time as part of the chart (the x axis)
con = createConnection()

username = 'spotify'
repo_name = 'luigi'
commits = getCommitIds(con, username, repo_name)

stats = Array.new

commits.each { |commit|
    patches = getPatches(con, commit[0], PYTHON)
    cd = CodeChurn.new()

    patches.each { |patch|
        #The first element is the file name
        if(patch[1] != nil)
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
                    cd.commentDeletion(1)
                    #commentDeletion += 1
                elsif comment[0] == '+'
                    #Addition
                    cd.commentAddition(1)
                    #commentAddition += 1
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
                            cd.codeDeletion(1)
                            #codeDeletions += 1
                        elsif line[0] == '-' || line[0] == '+'
                            #Addition
                            cd.codeAddition(1)
                            #codeAdditions += 1
                        end
                    end

                elsif line[0] == '@@'
                    #Ignore
                end
            }
        end
    }

    #puts "comment added = #{cd.commentAddition(0)}"
    #puts "comment deleted = #{cd.commentDeletion(0)}"

    #puts "code added = #{cd.codeAddition(0)}"
    #puts "code deleted = #{cd.codeDeletion(0)}"

    #puts "total code  = #{cd.totalCodes}"
    #puts "total comments = #{cd.totalComments}"
    #puts "\n"

    stats.push(cd)
}

commentData = createStateArray(stats)

#bg == background
Gchart.line(:data => commentData.codeAddition, :title => "#{username} / #{repo_name}", :size => '700x200', :legend => 'Code Additions', :axis => "hello" )

Gchart.line(:data => commentData.codeDeletion, :title => "#{username} / #{repo_name}", :size => '700x200', :legend => 'Code Deletions', :axis => "hello" )

Gchart.line(:data => commentData.commentAddition, :title => "#{username} / #{repo_name}", :size => '700x200', :legend => 'Comment Additions', :axis => "hello" )

Gchart.line(:data => commentData.commentDeletion, :title => "#{username} / #{repo_name}", :size => '700x200', :legend => 'Comment Deletion', :axis => "hello" )

# :legend => ['x axis', 'y-axis']
#puts stats

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
