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
        author_id = toInteger(getUserId(con, User.new(commit["author"]["login"], commit["commit"]["author"]["date"])))

        
        #puts "author_id = #{author_id}"

        # Get the commiter's info
        # Insert the committer (if not already inserted)
        commiter_id = toInteger(getUserId(con, User.new(commit["committer"]["login"], commit["commit"]["committer"]["date"])))

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
    tagList = github.git_data.references.list username, repo_name, ref:'tags'

    tagList.body.each { |tag|

        tagMore = (github.git_data.tags.get username, repo_name, tag["object"]["sha"]).body

        # Get the commit sha
        sha = tagMore["object"]["sha"]

        # Get the tag name
        name = tagMore["tag"]

        # Get the tag message
        message = tagMore["message"]

        # Get the date the tag was added
        date = tagMore["tagger"]["date"]

        #puts dates

        #sha = tag["commit"]["sha"]
        #test the actual command
        #tagMore = github.git_data.tags.get username, repo_name, sha
        insertTag(con, Tag.new(sha, name, message, date))
    }
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
    puts 'working on files'
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
        file = Nokogiri::HTML(open(file["raw_url"]))

        #puts commit_id[0]
        insertFileId(con, Sourcefile.new(commit_id, filename, additions, deletions, patch, file.children.children.children.children.text))
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

#getAllCommits(con, github, 'dataBaseError', 'intro-webdev')

getAllCommits(con, github, 'stormpath', 'stormpath-rails')

rate = Rate.new(github)

puts rate.rate()

con.commit()