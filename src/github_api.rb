gem 'json', '~> 1.7.7'
gem 'github_api', '=0.9.7'
require 'github_api'
require 'nokogiri'
require 'open-uri'
require 'socket'    # Required to catch socket error
require_relative 'database_interface'
require_relative 'utility'
require_relative 'regex'
require_relative 'progress'

$stdout.sync = true
$stderr.sync = true

HOUR = 3600
APP_TITLE = "Github Scraper"

#Command line arguements in order
repo_owner, repo_name, username, password = "", "", "", ""

if ARGV.size == 4
    repo_owner, repo_name = ARGV[0], ARGV[1]
    username, password = ARGV[2], ARGV[3]
end

#TODO redirect error output to log file.

class Rate
    def initialize(github)
        getRateRemaining(github)
        @timeStart = Time.now
        @limit = false
    end

    def decreaseRate(amount)
        if @rateRemaining < amount
            @limit = true
            return false
        end
        @rateRemaining = @rateRemaining - amount
        
        return true
    end


    def getRateRemaining(github)
        @rateRemaining = github.ratelimit_remaining
    end

    def checkaRte(github)
        getRateRemaining(github)
        return @rateRemaining
    end

    def rate()
        @rateRemaining
    end

    def getTime()
        @timeStart
    end

    def runOut()
        if @rateRemaining <= 0
            return true
        else
            return false
        end
    end

    def waitIsOver(time)
        if (time - @timeStart)/3600 >= 1
            return true
        else
            return false
        end
    end

    def getTimeRemaining(time)
        3600 - (time - @timeStart)
    end
end

#Github.repos.list user: 'dataBaseError'
#puts "Password"
#password = gets.chomp

#\\n([+-][\w\s\.*;\/]*)
#\\n[+-]([^(\\)]*)


github = Github.new do | config |
    config.auto_pagination = true
    config.mime_type = :full 
    config.login = username
    config.password = password
end

#rate = Rate.new(github)

#puts rate.rate()

#a = github.repos.commits.all 'tinfoilhat', 'tinfoil-sms'

#puts rate.checkRate(github)
#puts a.length

#commitFile = File.new("test.log", "w")
#    a.each { |x|  commitFile.puts x }
#commitFile.close

#response = github.repos.commits.get_request(a.body[0]["url"])

#file = Nokogiri::HTML(open(response.body["files"][0]["raw_url"]))



#a = Github.repos.commits.all 'tinfoilhat', 'tinfoil-sms'

#puts a.length

#peter-murach / github
#github.git_data.tags.get 'peter-murach', 'github', 'cadf5847a03f9fb3ca7e99ca355f27c340c3f8bc'

#github.repos.tags 'peter-murach', 'github'

#a = github.repos.list_tags 'peter-murach', 'github'

#a = github.repos.list_tags 'torvalds', 'linux'

#con = createConnection()
def waitOnRate(con, github, amount)
    while github.ratelimit_remaining < amount
        con.close()
        sleep(HOUR)
        con = Github_database.createConnection()
    end
end

def getAllCommits(con, github, username, repo_name)
    
    progress_indicator = Progress.new(APP_TITLE)

    progress_indicator.puts "Getting all commits..."
    #rate = Rate.new(github)
    # Get the repo's commits

    begin
        #Put 1000 since it is a large request but it is unlikely that a repo will contain more than 1000*100 commits
        waitOnRate(con, github, 1000)

        allCommits = github.repos.commits.all username, repo_name
    rescue Exception => e
        puts e
        retry
    end

    progress_indicator.total_length = allCommits.body.length

    #puts rate.getTimeRemaining(Time.now)

    # Get the repo's database Id
    repo_id = Utility.toInteger(Github_database.getRepoId(con, repo_name, username))

    allCommits.body.each { |commit|

        progress_indicator.percentComplete(nil,"Storing Commits")

        # Get the commit's sha
        sha = commit["sha"]

        # Get the author's info
        # Insert the author (if not already inserted)
        
        #todo check if commit["author"] == nil
        author_name = nil
        if commit["author"] == nil
            author_name = commit["commit"]["author"]["name"]
        else
            author_name = commit["author"]["login"]
        end
        author_date = commit["commit"]["author"]["date"]

        author_id = Utility.toInteger(Github_database.getUserId(con, User.new(author_name, author_date)))

        
        #puts "author_id = #{author_id}"

        # Get the commiter's info
        # Insert the committer (if not already inserted)
        
        commiter_name = nil
        if commit["committer"] == nil
            commiter_name = commit["commit"]["committer"]["name"]
        else
            commiter_name = commit["committer"]["login"]
        end

        commiter_date = commit["commit"]["committer"]["date"]

        commiter_id = Utility.toInteger(Github_database.getUserId(con, User.new(commiter_name, commiter_date)))

        #puts "commiter_id = #{commiter_id}"

        # Get the commit message
        message = commit["commit"]["message"]

        # Insert the commits into the database.

        # Get the insert id
        commit_id = Utility.toInteger(Github_database.insertCommitsIds(con, Commit.new(repo_id, commiter_id, author_id, message, sha)))
    
        #parentHash = Array.new
        # Insert the parents
        commit["parents"].each { |parent|
            #parentHash.push parent["sha"]
            Github_database.insertParent(con, commit_id, parent["sha"])
        }

        setFiles(con, github, commit["url"], commit_id)
    }

    #progress_indicator.puts 'working on tags'

    begin

        # Get all the tags
        tagList = github.git_data.references.list username, repo_name, ref:'tags'

        progress_indicator.total_length = tagList.body.length
        progress_indicator.count = 0

        tagList.body.each { |tag|

            progress_indicator.percentComplete(nil, "Storing Tags")

            sha, name, message, date = "", "", "", ""
            begin
               tagMore = (github.git_data.tags.get username, repo_name, tag["object"]["sha"]).body
                # Get the commit sha
                sha = tagMore["object"]["sha"]

                # Get the tag name
                name = tagMore["tag"]

                # Get the tag message
                message = tagMore["message"]

                if message[-1] == "\n"
                    message = message[0..-2]
                end

                # Get the date the tag was added
                date = tagMore["tagger"]["date"]

            rescue Github::Error::NotFound => e
                sha = tag["object"]["sha"]
                name = tag["ref"].scan(TAG_REGEX)[0][0]
                commit = github.repos.commits.get(username, repo_name, tag["object"]["sha"])
                message = commit.body["commit"]["message"]
                date = commit.body["commit"]["committer"]["date"]
            end
            Github_database.insertTag(con, Tag.new(repo_id, sha, name, message, date))
        }
    rescue Github::Error::GithubError => e
        puts e.message
    end

    # Set the types of files this project uses
    progress_indicator.puts "settings file types."
    Github_database.setFileTypes(con, repo_name, username)

end

def setFiles(con, github, commitUrl, commit_id)
    #puts 'working on files'

    begin
        waitOnRate(con, github, 2)
        # Get all files
        commitFiles = github.repos.commits.get_request(commitUrl).body["files"]
    rescue Github::Error::Unauthorized => e
        puts e
        #puts github.ratelimit_remaining
        #puts rate.getTimeRemaining
        #a = gets
        # Try again
        retry
    rescue Github::Error::ServiceError
        puts e
        #puts github.ratelimit_remaining
        #a = gets
        retry
    rescue Exception => e
        puts e
        #a = gets
        retry
    end

    commitFiles.each { |file|

        # Get Additions
        additions = file["additions"]

        # Get Deletions
        deletions = file["deletions"]

        # Get file name
        filename = file["filename"]

        # Get patch info
        patch = file["patch"]

        if patch != nil
            patch.gsub(NEWLINE_FIXER,"\n")
        end

    count = 0
    begin
            waitOnRate(con, github, 2)
            # Get the file that was updated
            url = URI::encode(file["raw_url"].force_encoding('binary'))
            #puts url
    rescue Exception => e
        count +=1
        puts e
        if count < 3
                retry
        end
    end

    count = 0

        #body = nil

        #Added try catch since some file urls do not work. (such as file to large)
        if filename.match(/.*?\.java/)
            begin

                valid = false
                while !valid
                    body = ""
                    # Open up the url 
                    urlIO = open(url)

                    # Read the io buffer into the body of the file
                    urlIO.each { |line|
                        body += line
                    }

                    if body.match(/^<!DOCTYPE html>/)
                        puts "bad url"
                        puts "url: #{url}"
                        puts github.ratelimit_remaining
                        #a = gets
                        puts body
                        #a = gets
                        #retry
                        valid = false
                    else
                        valid = true
                    end
                end
                #file = Nokogiri::HTML(open(url)) do |config|
                #    config.default_html.
                #end
                #body = file.children.children.children.children.text

                #puts ""
                #puts "filename #{filename}"

                # Remove carriage return
                body = body.gsub(NEWLINE_FIXER,"\n")

                #puts "body #{body}"
                #puts ""
                #puts "patch #{patch}"

                #a = gets
                #puts commit_id[0]
                
            rescue OpenURI::HTTPError => e 
                puts e
                # Add the error message to the url link so that when reading the
                # database it will be easier to tell that the there was a problem
                # getting the file.
                body = "#{e}\n#{url}"
                count += 1
                if count < 3
                    retry
                end
            rescue SocketError => e
                puts e
                #puts github.ratelimit_remaining
                body = "#{e}\n#{url}"
                retry
            rescue Faraday::Error::ConnectionFailed => e
                puts e
                #puts github.ratelimit_remaining
                body = "#{e}\n#{url}"
                retry
            rescue Errno::ECONNRESET => e
                puts e
                #puts github.ratelimit_remaining
                body = "#{e}\n#{url}"
                retry
            rescue Exception => e
                puts e
                #puts github.ratelimit_remaining
                body = "#{e}\n#{url}"
                retry
            end
        else
            body = url
        end
        Github_database.insertFileId(con, Sourcefile.new(commit_id, filename, additions, deletions, patch, body))
    }
end
=begin
        if rate.checkRate(github) <= 0
            puts "press enter to check the rate again"
        end
        while rate.checkRate(github) <= 0
            puts "rate = #{rate.rate}"
            gets.chomp
        end
=end

#TODO add something that keeps track of all the file types in the program ()

con = Github_database.createConnection()

start_time = Time.now

#java large
getAllCommits(con, github, repo_owner, repo_name)

finish_time = Time.now

# Calculate the run time
puts "Number of seconds = #{finish_time - start_time}"

rate = Rate.new(github)

puts rate.rate()

con.commit()
