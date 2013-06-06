require 'mysql'

module Stats_db
    require_relative 'utility'

    DATABASE = 'project_stats'
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
    BODY = 'body'
    #Depreciated
    #TOTAL_COMMENTS = 'total_comments'
    #TOTAL_CODE = 'total_code'
    TOTAL_ADDED_COMMENTS = 'total_comment_addition'
    TOTAL_DELETED_COMMENTS = 'total_comment_deletion'
    TOTAL_ADDED_CODE = 'total_code_addition'
    TOTAL_DELETED_CODE = 'total_code_deletion'

    # File
    FILE_ID = 'file_id'
    COMMIT_REFERENCE = 'commit_reference'
    NAME = 'name'
    #Depreciated
    #NUM_COMMENTS = 'num_comments'
    #NUM_CODE = 'num_code'
    ADDED_COMMENTS = 'comment_addition'
    DELETED_COMMENTS = 'comment_deletion'
    ADDED_CODE = 'code_addition'
    DELETED_CODE = 'code_deletion'

    def Stats_db.createConnection()
        Mysql.new(HOST, USERNAME, PASSWORD, DATABASE)
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
    def Stats_db.insertCommit(con, repo_id, date, body, comments_added, comments_deleted, code_added, code_deleted)

        pick = con.prepare("INSERT INTO #{COMMITS} (#{REPO_REFERENCE}, #{COMMIT_DATE}, #{BODY}, #{TOTAL_ADDED_COMMENTS}, #{TOTAL_DELETED_COMMENTS}, #{TOTAL_ADDED_CODE}, #{TOTAL_DELETED_CODE}) VALUES (?, ?, ?, ?, ?, ?, ?)")
        pick.execute(repo_id, date, body, comments_added, comments_deleted, code_added, code_deleted)

        return Utility.toInteger(pick.insert_id)
    end

    # Update the given commits to the database
    # +con+:: the database connection used. 
    # +repo_name+:: the name of the repository
    # +commiter+:: the +User+ that committed the commit
    # +author+:: the +User+ that wrote the code that is part of this commit
    # +body+:: the commit message
    # +sha+:: the uuid for the commit
    def Stats_db.updateCommit(con, commit_id, comments_added, comments_deleted, code_added, code_deleted)

        pick = con.prepare("UPDATE #{COMMITS} SET #{TOTAL_ADDED_COMMENTS}=?, #{TOTAL_DELETED_COMMENTS}=?, #{TOTAL_ADDED_CODE}=?, #{TOTAL_DELETED_CODE}=? WHERE #{COMMIT_ID} = ?")
        pick.execute(comments_added, comments_deleted, code_added, code_deleted, commit_id)

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

    def Stats_db.insertFile(con, commit_id, name, comments_added, comments_deleted, code_added, code_deleted)

        pick = con.prepare("INSERT INTO #{FILE} (#{COMMIT_REFERENCE}, #{NAME}, #{ADDED_COMMENTS}, #{DELETED_COMMENTS}, #{ADDED_CODE}, #{DELETED_CODE}) VALUES (?, ?, ?, ?, ?, ?)")

        pick.execute(commit_id, name, comments_added, comments_deleted, code_added, code_deleted)

        return Utility.toInteger(pick.insert_id)
    end
end