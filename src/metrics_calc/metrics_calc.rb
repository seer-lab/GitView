require_relative '../database/database_interface'

con = Github_database.createConnection()

Github_database.getRepos(con).each do |repo_id, repo_owner, repo_name|

    prev_sha=nil
    Github_database.getCommitsByDate(con, repo_owner, repo_name).each do |files|

    end
end
