require 'mysql'

module Stats_db
    require_relative 'utility'

    $DATABASE = 'project_stats'
    HOST = 'localhost'
    USERNAME = 'git_miner'
    PASSWORD = 'pickaxe'

    #Tables:
    REPO = 'repositories'
    COMMITS = 'commits'
    FILE = 'file'

    # Repo
    REPO_ID = 'repo_id'
    REPO_NAME = 'repo_name'
    REPO_OWNER = 'repo_owner'

    # Commits
    COMMIT_ID = 'commit_id'
    REPO_REFERENCE ='repo_reference'
    COMMIT_DATE = 'commit_date'
    COMMITTER_ID = 'committer_id'
    AUTHOR_ID = 'author_id'
    BODY = 'body'
    TOTAL_ADDED_COMMENTS = 'total_comment_addition'
    TOTAL_DELETED_COMMENTS = 'total_comment_deletion'
    TOTAL_MODIFIED_COMMENT = 'total_comment_modified'
    TOTAL_ADDED_CODE = 'total_code_addition'
    TOTAL_DELETED_CODE = 'total_code_deletion'
    TOTAL_MODIFIED_CODE = 'total_code_modified'
    
    # User
    USER = 'user'
    USER_ID = 'user_id'
    #COMMIT_REFERENCE = 'commit_reference'
    #NAME = 'name'

    # File
    FILE_ID = 'file_id'
    COMMIT_REFERENCE = 'commit_reference'
    PATH = 'path'
    NAME = 'name'
    ADDED_COMMENTS = 'comment_addition'
    DELETED_COMMENTS = 'comment_deletion'
    MODIFIED_COMMENTS = 'comment_modified'
    ADDED_CODE = 'code_addition'
    DELETED_CODE = 'code_deletion'
    MODIFIED_CODE = 'code_modified'

    # Tag
    TAG = 'tags'
    TAG_ID = 'tag_id'
    #COMMIT_REFERENCE = 'commit_reference'
    TAG_SHA = 'tag_sha'
    TAG_NAME = 'tag_name'
    TAG_DESC = 'tag_description'
    TAG_DATE = 'tag_date'

    def Stats_db.createConnection()
        Mysql.new(HOST, USERNAME, PASSWORD, $DATABASE)
    end

    def Stats_db.createConnectionThreshold(threshold, multi)
        
        $DATABASE = "#{$DATABASE}#{threshold}"
        
        if multi
            $DATABASE = "#{$DATABASE}_M"
        end

        Mysql.new(HOST, USERNAME, PASSWORD, $DATABASE)
    end


    # Get the repository's id stored in the database with the given name
    # Params:
    # +con+:: the database connection used. 
    # +name+:: the name of the repository
    def Stats_db.getRepoId(con, name, owner)
        pick = con.prepare("SELECT #{REPO_ID} FROM #{REPO} WHERE #{REPO_NAME} LIKE ? AND #{REPO_OWNER} LIKE ?")
        pick.execute(name, owner)
    
        result = pick.fetch
    
        if(result == nil)
            result = insertRepo(con, name, owner)
        end
        #There should be only 1 id return anyways.
        return Utility.toInteger(result)
    end


    def Stats_db.getRepos(con)
        pick = con.prepare("SELECT * FROM #{REPO}")
        pick.execute

        rows = pick.num_rows
        results = Array.new(rows)

        rows.times do |x|
            results[x] = pick.fetch
        end

        #results.each { |x| puts x }
        return results
    end

    # Insert the given repository to the database
    # +con+:: the database connection used. 
    # +repo+:: the name of the repository
    def Stats_db.insertRepo(con, repo, owner)
        pick = con.prepare("INSERT INTO #{REPO} (#{REPO_NAME}, #{REPO_OWNER}) VALUES (?, ?)")
        pick.execute(repo, owner)

        return Utility.toInteger(pick.insert_id)
    end

    # Get all the commits stored in the database
    # Params:
    # +con+:: the database connection used. 
    def Stats_db.getCommits(con)
        pick = con.prepare("SELECT * FROM #{COMMITS}")
        pick.execute

        rows = pick.num_rows
        results = Array.new(rows)

        rows.times do |x|
            results[x] = pick.fetch
        end

        #results.each { |x| puts x }
        return results
    end

    # Insert the given commits to the database
    # +con+:: the database connection used. 
    # +repo_name+:: the name of the repository
    # +date+:: the date the commit was committed
    # +body+:: the commit message
    # +comments+:: the number of lines of comments in the commit
    # +code+:: the number of lines of code in the commit
    def Stats_db.insertCommit(con, repo_id, date, body, comments_added, comments_deleted, comment_modified, code_added, code_deleted, code_modified, committer_id, author_id)

        pick = con.prepare("INSERT INTO #{COMMITS} (#{REPO_REFERENCE}, #{COMMIT_DATE}, #{BODY}, #{TOTAL_ADDED_COMMENTS}, #{TOTAL_DELETED_COMMENTS}, #{TOTAL_MODIFIED_COMMENT}, #{TOTAL_ADDED_CODE}, #{TOTAL_DELETED_CODE}, #{TOTAL_MODIFIED_CODE}, #{COMMITTER_ID}, #{AUTHOR_ID}) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
        pick.execute(repo_id, date, body, comments_added, comments_deleted, comment_modified, code_added, code_deleted, code_modified, committer_id, author_id)

        return Utility.toInteger(pick.insert_id)
    end

    # Update the given commits to the database
    # +con+:: the database connection used. 
    # +repo_name+:: the name of the repository
    # +commiter+:: the +User+ that committed the commit
    # +author+:: the +User+ that wrote the code that is part of this commit
    # +body+:: the commit message
    # +sha+:: the uuid for the commit
    def Stats_db.updateCommit(con, commit_id, comments_added, comments_deleted, comment_modified,code_added, code_deleted, code_modified)

        pick = con.prepare("UPDATE #{COMMITS} SET #{TOTAL_ADDED_COMMENTS}=?, #{TOTAL_DELETED_COMMENTS}=?, #{TOTAL_MODIFIED_COMMENT}=?, #{TOTAL_ADDED_CODE}=?, #{TOTAL_DELETED_CODE}=?, #{TOTAL_MODIFIED_CODE}=? WHERE #{COMMIT_ID} = ?")
        pick.execute(comments_added, comments_deleted, comment_modified, code_added, code_deleted, code_modified, commit_id)

        nil
        #return Utility.toInteger(commit_id)
    end

    def Stats_db.getFiles(con)
        pick = con.prepare("SELECT * FROM #{FILE}")
        pick.execute

        rows = pick.num_rows
        results = Array.new(rows)

        rows.times do |x|
            results[x] = pick.fetch
        end

        #results.each { |x| puts x }
        return results
    end

    def Stats_db.insertFile(con, commit_id, path, name, comments_added, comments_deleted, comment_modified, code_added, code_deleted, code_modified)

        pick = con.prepare("INSERT INTO #{FILE} (#{COMMIT_REFERENCE}, #{PATH}, #{NAME}, #{ADDED_COMMENTS}, #{DELETED_COMMENTS}, #{MODIFIED_COMMENTS}, #{ADDED_CODE}, #{DELETED_CODE}, #{MODIFIED_CODE}) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")
        pick.execute(commit_id, path, name, comments_added, comments_deleted, comment_modified, code_added, code_deleted, code_modified)

        return Utility.toInteger(pick.insert_id)
    end

    def Stats_db.insertUser(con, name)
        pick = con.prepare("INSERT INTO #{USER} (#{NAME}) VALUES (?)")

        pick.execute(name)

        return Utility.toInteger(pick.insert_id)
    end

    def Stats_db.getUserId(con, name)
        pick = con.prepare("SELECT #{USER_ID} FROM user WHERE #{NAME} LIKE ?")
        pick.execute(name)

        result = pick.fetch

        #puts "result #{result}"
        if(result == nil)
            result = insertUser(con, name)
        end
        #puts "#{user.name} id = #{result}"

        return Utility.toInteger(result)

    end

    def Stats_db.insertTag(con, repo_id, sha, name, description, date)
        pick = con.prepare("INSERT INTO #{TAG} (#{REPO_REFERENCE}, #{TAG_SHA}, #{TAG_NAME}, #{TAG_DESC}, #{TAG_DATE}) VALUES (?, ?, ?, ?, ?)")
        pick.execute(repo_id, sha, name, description, date)
     
        return Utility.toInteger(pick.insert_id)
    end

    # Get the repositories stored in the database
    def Stats_db.getRepos(con)
        pick = con.prepare("SELECT #{REPO_OWNER}, #{REPO_NAME} FROM #{REPO}")
        pick.execute()
    
        rows = pick.num_rows
        results = Array.new(rows)

        rows.times do |x|
            results[x] = pick.fetch
        end

        #There should be only 1 id return anyways.
        return results
    end 

    # Get the commit totals stored in the database
    # TODO add constants to SQL statement
    def Stats_db.getCommitStats(con, repo, user)
        pick = con.prepare("SELECT DISTINCT c.commit_date, c.total_comment_addition, c.total_comment_deletion, c.total_comment_modified, c.total_code_addition, c.total_code_deletion, c.total_code_modified FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? ORDER BY c.commit_date")
        pick.execute(repo, user)
    
        rows = pick.num_rows
        results = Array.new(rows)

        rows.times do |x|
            results[x] = pick.fetch
        end

        #There should be only 1 id return anyways.
        return results
    end
end
