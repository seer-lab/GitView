gem 'json', '~> 1.7.7'
require 'github_api'
require 'nokogiri'
require 'open-uri'
require_relative 'database_interface'


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
end

#Github.repos.list user: 'dataBaseError'
puts "Password"
password = gets.chomp

#\\n([+-][\w\s\.*;\/]*)
#\\n[+-]([^(\\)]*)


github = Github.new do | config |
    config.auto_pagination = true
    config.mime_type = :full 
    config.login = 'dataBaseError'
    config.password = password
end


rate = Rate.new(github)

puts rate.rate()

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

def getAllCommits(con, github, username, repo_name)
    
    puts "Getting all commits..."

    # Get the repo's commits
    allCommits = github.repos.commits.all username, repo_name

    # Get the repo's database Id
    repo_id = toInteger(getRepoId(con, repo_name, username))

    allCommits.body.each { |commit|

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

        author_id = toInteger(getUserId(con, User.new(author_name, author_date)))

        
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

        commiter_id = toInteger(getUserId(con, User.new(commiter_name, commiter_date)))

        #puts "commiter_id = #{commiter_id}"

        # Get the commit message
        message = commit["commit"]["message"]

        # Insert the commits into the database.

        # Get the insert id
        commit_id = toInteger(insertCommitsIds(con, Commit.new(repo_id, commiter_id, author_id, message, sha)))
    
        #parentHash = Array.new
        # Insert the parents
        commit["parents"].each { |parent|
            #parentHash.push parent["sha"]
            insertParent(con, commit_id, parent["sha"])
        }

        setFiles(con, github, commit["url"], commit_id)
    }

    puts 'working on tags'
    begin

        # Get all the tags
        tagList = github.git_data.references.list username, repo_name, ref:'tags'

        tagList.body.each { |tag|

            tagMore = (github.git_data.tags.get username, repo_name, tag["object"]["sha"]).body

            # Get the commit sha
            sha = tagMore["object"]["sha"]

            # Get the tag name
            name = tagMore["tag"]

            # Get the tag message
            # TODO remove the '\n' at the end
            message = tagMore["message"]

            # Get the date the tag was added
            date = tagMore["tagger"]["date"]

            #puts dates

            #sha = tag["commit"]["sha"]
            #test the actual command
            #tagMore = github.git_data.tags.get username, repo_name, sha
            insertTag(con, Tag.new(sha, name, message, date))
        }
    rescue Github::Error::GithubError => e
        puts e.message
    end

end

#Tag stuff
=begin 
puts 'working on tags'
tagList = github.git_data.references.list 'peter-murach', 'github', ref:'tags'

tagList.body.each { |tag|

    tagMore = (github.git_data.tags.get 'peter-murach', 'github', tag["object"]["sha"]).body

    # Get the commit sha
    sha = tagMore["object"]["sha"]

    # Get the tag name
    name = tagMore["tag"]

    #Get the tag message
    message = tagMore["message"]
    #sha = tag["commit"]["sha"]
    #test the actual command
    #tagMore = github.git_data.tags.get username, repo_name, sha
    insertTag(con, Tag.new(sha, name, message))
}
=end

def setFiles(con, github, commitUrl, commit_id)
    # TODO decide on whether to ignore /doc folder or not, since the projects im looking for should have source code documentation (so /doc would be duplication or not what im looking for)
    puts 'working on files'

    # Get all files
    commitFiles = github.repos.commits.get_request(commitUrl).body["files"]

    commitFiles.each { |file|

        # Get Additions
        additions = file["additions"]

        # Get Deletions
        deletions = file["deletions"]

        # Get file name
        filename = file["filename"]

        # Get patch info
        patch = file["patch"]

        # Get the file that was updated
        url = URI::encode(file["raw_url"].force_encoding('binary'))
        #puts url


        #body = nil

        #Added try catch since some file urls do not work. (such as file to large)
        begin
            file = Nokogiri::HTML(open(url))
            body = file.children.children.children.children.text
            #puts commit_id[0]
            
        rescue OpenURI::HTTPError => e
            puts e
            # Add the error message to the url link so that when reading the
            # database it will be easier to tell that the there was a problem
            # getting the file.
            body = "#{e}\n#{url}"
        end
        insertFileId(con, Sourcefile.new(commit_id, filename, additions, deletions, patch, body))
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

con = createConnection()

start_time = Time.now
#really small
#getAllCommits(con, github, 'dataBaseError', 'intro-webdev')

#small
#getAllCommits(con, github, 'stormpath', 'stormpath-rails')

#slightly small
#getAllCommits(con, github, 'rauhryan', 'ghee')

#medium
#getAllCommits(con, github, 'gnu-user', 'free-room-website')

#medium-large
#getAllCommits(con, github, 'spotify', 'luigi')

#huge
#getAllCommits(con, github, 'peter-murach', 'github')

#Huge (because of libraries commited)
#getAllCommits(con, github, 'tinfoilhat', 'tinfoil-sms')

finish_time = Time.now

# Calculate the run time
total_time = "Number of seconds = #{finish_time - start_time}"

puts total_time

rate = Rate.new(github)

puts rate.rate()

con.commit()