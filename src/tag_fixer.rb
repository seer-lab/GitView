gem 'github_api', '=0.9.7'
require 'github_api'
require_relative 'utility'
require_relative 'regex'
require_relative 'database_interface'

#Command line arguements in order
username, password = "dataBaseError", ""

password = gets.chomp

github = Github.new do | config |
    config.auto_pagination = true
    config.mime_type = :full 
    config.login = username
    config.password = password
end

con = Github_database.createConnection()

repos = Github_database.getRepos(con)

repos.each { |repo_id, repo_name, repo_owner|
    begin

        # Get all the tags
        tagList = github.git_data.references.list repo_owner, repo_name, ref:'tags'

        tagList.body.each { |tag|
            sha, name, message, date = "", "", "", ""
            begin
                tagMore = (github.git_data.tags.get repo_owner, repo_name, tag["object"]["sha"]).body
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
                commit = github.repos.commits.get(repo_owner, repo_name, tag["object"]["sha"])
                message = commit.body["commit"]["message"]
                date = commit.body["commit"]["committer"]["date"]
            end
            
            Github_database.insertTag(con, Tag.new(repo_id, sha, name, message, date))
        }
    rescue Github::Error::GithubError => e
        puts e.message
    end
}