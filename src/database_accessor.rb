require 'gchart'
require 'googl'
require_relative 'database_interface'

#The expression to match the given extension

#The multi-line comment regex only catches multi-line comment style done on 1 line.
# Need to add support to go through the added lines and look for the multi-line comment start and end to identify who many lines it is.
PYTHON_COMMENT_EXPR = /(\+|-).*?((#.*)|(""".*"""))\n/

RUBY_COMMENT_EXPR = /(\+|-).*?((#.*))\n/

DIFF_REGULAR_EXPR =/(\+|-|(@@))(.*?)\n/

#Can break up file into lines
# Note, last line must have a \n added to it.
LINE_EXPR = /(.*?)\n/

PYTHON = 'py'

RUBY = 'rb'


class CodeChurn
    def initialize()
        @codeAddition = 0
        @codeDeletion = 0
        @commentAddition = 0
        @commentDeletion = 0
        @date = nil
    end 

    def setDate(value)
        @date = value
    end

    def date()
        @date
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
        @date = Array.new
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

    def datePush(value)
        @date.push(value)
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

    def date()
        @date
    end
end

def getFiles(con, extension)
    pick = con.prepare("SELECT #{FILE} FROM #{FILE} AS f INNER JOIN #{COMMITS} AS c ON f.#{COMMIT_REFERENCE} = c.#{COMMIT_ID} INNER JOIN #{REPO} AS r ON c.#{REPO_REFERENCE} = r.#{REPO_ID} WHERE #{NAME} LIKE ?")
    pick.execute("#{EXTENSION_EXPRESSION}#{extension}")

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end

def getPatches(con, commit_id, extension)
    pick = con.prepare("SELECT f.#{NAME}, f.#{PATCH}, com.#{DATE} FROM #{COMMITS} AS c INNER JOIN #{USERS} AS com ON c.#{COMMITER_REFERENCE} = com.#{USER_ID} INNER JOIN #{FILE} AS f ON c.#{COMMIT_ID} = f.#{COMMIT_REFERENCE} WHERE f.#{COMMIT_REFERENCE} = ? AND f.#{NAME} LIKE ?")
    pick.execute(commit_id, "#{EXTENSION_EXPRESSION}#{extension}")

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end

def getCommitIds(con, username, repo)
    pick = con.prepare("SELECT c.#{COMMIT_ID} FROM #{REPO} AS r INNER JOIN #{COMMITS} AS c ON r.#{REPO_ID} = c.#{REPO_REFERENCE} WHERE r.#{REPO_NAME} LIKE ? AND r.#{REPO_OWNER} LIKE ?")

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

        # Add the date the code was committed
        metricArray.datePush(codeChurn.date)

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
con = Github_database.createConnection()

#username, repo_name = 'peter-murach', 'github'
username, repo_name = 'spotify', 'luigi'
commits = getCommitIds(con, username, repo_name)

stats = Array.new

# Commit index
#i = 0

# Number of commits without python code
numOfNonCodeCommits = 0

commits.each { |commit|
    patches = getPatches(con, commit[0], PYTHON)
    #patches = getPatches(con, commit[0], RUBY)

    cd = CodeChurn.new()

    #Note that if the date is nil, then the entry patch is empty, if the patch is empty, then unrecognized code was committed. This should be ignored
    if patches[0] == nil
        numOfNonCodeCommits += 1
    else
        patches.each { |patch|

            #The first element is the file name
            #Second is the diff for the file for this commit against it's previous version
            #Third is the date the committer committed the files.

            #Set the date
            cd.setDate(patch[2])

            if patch[1] != nil

                #Ensure that the last new line isnt there
                if patch[1][patch[1].size-1] != "\n"
                    patch[1] += "\n"
                end

                #lines = patch[1].scan(LINE_EXPR)

                #lines.each { |line|
                    comments = patch[1].scan(PYTHON_COMMENT_EXPR)
                    #comments = patch[1].scan(RUBY_COMMENT_EXPR)

                    codes = patch[1].scan(DIFF_REGULAR_EXPR)

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

                    codes.each { |code|

                        if code[0] == '-' || code[0] == '+'

                            # Check if the line is spaces and a comment
                            # TODO just remove these lines while parsing the comments
                            if !code[2].match(/^\s*#(.*)/)

                                if code[0] == '-'
                                    #Deletion
                                    cd.codeDeletion(1)
                                    #codeDeletions += 1
                                elsif code[0] == '-' || code[0] == '+'
                                    #Addition
                                    cd.codeAddition(1)
                                    #codeAdditions += 1
                                end
                            end

                        elsif code[0] == '@@'
                            #Ignore
                        end
                    }
                #}
            end
        }
        stats.push(cd)
    end
}

=begin
    
rescue count = 0
x = 0
commits.each { |commit|
    patches = getPatches(con, commit[0], PYTHON)

    patches.each { |patch|
        if patches[0] == nil
            puts "patches nil"
            count +=1
            #break
        elsif commentData.date == nil
            puts "stat date = nil"
        else
            puts "original = #{patches[0][2]} , stats = #{commentData.date[x]}"
        end
    }
    a = gets
    x += 1
}
puts x
puts "#{count} # of nils"

commits.each { |commit|
    patches = getPatches(con, commit[0], PYTHON)

    if patches[0] == nil
        puts "nil"
    else
        puts  patches[0][0] 
    end
    a = gets
}
=end

commentData = createStateArray(stats)

puts "#{commentData.date.size + numOfNonCodeCommits} commits"
puts "#{numOfNonCodeCommits} commits with non python code"
puts "#{commentData.date.size} commits with python code"

#puts commentData.date
puts ""

#bg == background
puts Googl.shorten(Gchart.line(:data => commentData.codeAddition, :title => "#{username} / #{repo_name}", :size => '700x200', :legend => 'Code Additions' )).short_url

puts ""
puts Googl.shorten(Gchart.line(:data => commentData.codeDeletion, :title => "#{username} / #{repo_name}", :size => '700x200', :legend => 'Code Deletions' )).short_url
puts ""
puts Googl.shorten(Gchart.line(:data => commentData.commentAddition, :title => "#{username} / #{repo_name}", :size => '700x200', :legend => 'Comment Additions' )).short_url
puts ""
puts Googl.shorten(Gchart.line(:data => commentData.commentDeletion, :title => "#{username} / #{repo_name}", :size => '700x200', :legend => 'Comment Deletion', :axis => "hello" )).short_url

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

