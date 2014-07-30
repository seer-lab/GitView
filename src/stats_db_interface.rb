require 'mysql'

module Stats_db
    require_relative 'utility'
    require_relative 'method_statement_counter'

    $DATABASE = 'project_stats'
    HOST = 'localhost'
    USERNAME = 'git_miner'
    PASSWORD = 'pickaxe'

    #Tables:
    REPO = 'repositories'
    COMMITS = 'commits'
    FILE = 'file'
    METHOD = 'method'
    METHOD_STATEMENT = 'method_statement'

    # Repo
    REPO_ID = 'repo_id'
    REPO_NAME = 'repo_name'
    REPO_OWNER = 'repo_owner'

    # Commits
    COMMIT_ID = 'commit_id'
    REPO_REFERENCE ='repo_reference'
    SHA = 'sha_hash'
    COMMIT_DATE = 'commit_date'
    COMMITTER_ID = 'committer_id'
    AUTHOR_ID = 'author_id'
    BODY = 'body'
    TOTAL_COMMENT = 'total_comments'
    TOTAL_CODE = 'total_code'
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
    #TOTAL_COMMENT = 'total_comments'
    #TOTAL_CODE = 'total_code'
    ADDED_COMMENTS = 'comment_addition'
    DELETED_COMMENTS = 'comment_deletion'
    MODIFIED_COMMENTS = 'comment_modified'
    ADDED_CODE = 'code_addition'
    DELETED_CODE = 'code_deletion'
    MODIFIED_CODE = 'code_modified'

    # Method
    METHOD_ID = 'method_id'
    FILE_REFERENCE = 'file_reference'
    NEW_METHODS = 'new_methods'
    DELETED_METHODS = 'deleted_methods'
    MODIFIED_METHODS = 'modified_methods'

    # Method Statements
    STATEMENT_ID = 'statement_id'
    #FILE_REFERENCE = 'file_reference'
    NEW_CODE = 'new_code'
    NEW_COMMENT = 'new_comment'
    REMOVED_CODE = 'deleted_code'
    REMOVED_COMMENT = 'deleted_comment'
    MODIFIED_CODE_ADDED = 'modified_code_added'
    MODIFIED_COMMENT_ADDED = 'modified_comment_added'
    MODIFIED_CODE_DELETED = 'modified_code_deleted'
    MODIFIED_COMMENT_DELETED = 'modified_comment_deleted'

    # Tag
    TAG = 'tags'
    TAG_ID = 'tag_id'
    #COMMIT_REFERENCE = 'commit_reference'
    TAG_SHA = 'tag_sha'
    TAG_NAME = 'tag_name'
    TAG_DESC = 'tag_description'
    TAG_DATE = 'tag_date'
    COMMIT_SHA = 'commit_sha'

    # reference names
    
    FIRST_COMMIT = 'first_commit'
    LAST_COMMIT = 'last_commit'
    AVERAGE_METHODS_ADDED = 'average_methods_addded'
    AVERAGE_DELETED_METHODS = 'average_methods_deleted'
    AVERAGE_METHODS_MODIFIED = 'average_methods_modified'
    MONTH = 'month'

    def Stats_db.mergeThreshold(threshold)
        threshold = ((threshold.to_f*10).to_i).to_s
        if threshold.length == 1 
            threshold = "0#{threshold}"
        end
        return threshold
    end

    def Stats_db.createConnection()
        Mysql.new(HOST, USERNAME, PASSWORD, $DATABASE)
    end

    def Stats_db.createConnectionThreshold(threshold, multi)
        
        tempDB = "#{$DATABASE}#{threshold}"
        
        if multi
            tempDB = "#{tempDB}_M"
        end

        Mysql.new(HOST, USERNAME, PASSWORD, tempDB)
    end

    # Get the repo id if the given repository or nil if it does not exist.
    # Params:
    # +con+:: the database connection used. 
    # +name+:: the name of the repository
    # +owner+:: the owner of the repository
    def Stats_db.getRepoExist(con, name, owner)
        pick = con.prepare("SELECT #{REPO_ID} FROM #{REPO} WHERE #{REPO_NAME} LIKE ? AND #{REPO_OWNER} LIKE ?")
        pick.execute(name, owner)

        result = pick.fetch

        #There should be only 1 id return anyways.
        return Utility.toInteger(result)
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
        pick = con.prepare("SELECT #{REPO_ID}, #{REPO_NAME}, #{REPO_OWNER} FROM #{REPO}")
        pick.execute

        return Utility.fetch_results(pick)
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

        return Utility.fetch_results(pick)
    end

    # Get the most recent commit's sha hash from the database. 
    # +con+:: the database connection used. 
    # +repo_id+:: the id of the repository.
    def Stats_db.getLastCommit(con, repo_id)

        pick = con.prepare("select c.#{SHA} from #{COMMITS} as c where c.#{REPO_REFERENCE} = ? ORDER BY c.#{COMMIT_DATE} DESC LIMIT 1")

        pick.execute(repo_id)

        return Utility.toValue(pick.fetch)
    end

    # Insert the given commits to the database
    # +con+:: the database connection used. 
    # +repo_name+:: the name of the repository
    # +date+:: the date the commit was committed
    # +body+:: the commit message
    # +comments+:: the number of lines of comments in the commit
    # +code+:: the number of lines of code in the commit
    def Stats_db.insertCommit(con, repo_id, sha, date, body, total_comment, total_code, comments_added, comments_deleted, comment_modified, code_added, code_deleted, code_modified, committer_id, author_id)

        pick = con.prepare("INSERT INTO #{COMMITS} (#{REPO_REFERENCE}, #{COMMIT_DATE}, #{SHA}, #{BODY}, #{TOTAL_COMMENT}, #{TOTAL_CODE}, #{TOTAL_ADDED_COMMENTS}, #{TOTAL_DELETED_COMMENTS}, #{TOTAL_MODIFIED_COMMENT}, #{TOTAL_ADDED_CODE}, #{TOTAL_DELETED_CODE}, #{TOTAL_MODIFIED_CODE}, #{COMMITTER_ID}, #{AUTHOR_ID}) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
        pick.execute(repo_id, date, sha, body, total_comment, total_code, comments_added, comments_deleted, comment_modified, code_added, code_deleted, code_modified, committer_id, author_id)

        return Utility.toInteger(pick.insert_id)
    end

    # Update the given commits to the database
    # +con+:: the database connection used. 
    # +repo_name+:: the name of the repository
    # +commiter+:: the +User+ that committed the commit
    # +author+:: the +User+ that wrote the code that is part of this commit
    # +body+:: the commit message
    # +sha+:: the uuid for the commit
    def Stats_db.updateCommit(con, commit_id, total_comment, total_code, comments_added, comments_deleted, comment_modified, code_added, code_deleted, code_modified)

        pick = con.prepare("UPDATE #{COMMITS} SET #{TOTAL_COMMENT}=?, #{TOTAL_CODE}=?, #{TOTAL_ADDED_COMMENTS}=?, #{TOTAL_DELETED_COMMENTS}=?, #{TOTAL_MODIFIED_COMMENT}=?, #{TOTAL_ADDED_CODE}=?, #{TOTAL_DELETED_CODE}=?, #{TOTAL_MODIFIED_CODE}=? WHERE #{COMMIT_ID} = ?")
        pick.execute(total_comment, total_code, comments_added, comments_deleted, comment_modified, code_added, code_deleted, code_modified, commit_id)

        nil
        #return Utility.toInteger(commit_id)
    end

    def Stats_db.getFiles(con)
        pick = con.prepare("SELECT * FROM #{FILE}")
        pick.execute

        return Utility.fetch_results(pick)
    end

    def Stats_db.insertFile(con, commit_id, path, name, total_comment, total_code, comments_added, comments_deleted, comment_modified, code_added, code_deleted, code_modified)

        pick = con.prepare("INSERT INTO #{FILE} (#{COMMIT_REFERENCE}, #{PATH}, #{NAME}, #{TOTAL_COMMENT}, #{TOTAL_CODE}, #{ADDED_COMMENTS}, #{DELETED_COMMENTS}, #{MODIFIED_COMMENTS}, #{ADDED_CODE}, #{DELETED_CODE}, #{MODIFIED_CODE}) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
        pick.execute(commit_id, path, name, total_comment, total_code, comments_added, comments_deleted, comment_modified, code_added, code_deleted, code_modified)

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

        if(result == nil)
            result = insertUser(con, name)
        end

        return Utility.toInteger(result)

    end

    def Stats_db.insertTag(con, repo_id, sha, name, description, date, commit_sha)
        pick = con.prepare("INSERT INTO #{TAG} (#{REPO_REFERENCE}, #{TAG_SHA}, #{TAG_NAME}, #{TAG_DESC}, #{TAG_DATE}, #{COMMIT_SHA}) VALUES (?, ?, ?, ?, ?, ?)")
        pick.execute(repo_id, sha, name, description, date, commit_sha)
     
        return Utility.toInteger(pick.insert_id)
    end

    def Stats_db.getLastTag(con, repo_id)
        pick = con.prepare("select t.#{TAG_DATE} from #{TAG} as t where t.#{REPO_REFERENCE} = ? ORDER BY t.#{TAG_DATE} DESC LIMIT 1")

        pick.execute(repo_id)

        return Utility.toValue(pick.fetch)
    end

    # Get the commit totals stored in the database
    # TODO add constants to SQL statement
    def Stats_db.getCommitStats(con, repo, user)
        pick = con.prepare("SELECT DISTINCT c.commit_date, c.total_comment_addition, c.total_comment_deletion, c.total_comment_modified, c.total_code_addition, c.total_code_deletion, c.total_code_modified FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? ORDER BY c.commit_date")
        pick.execute(repo, user)
    
        return Utility.fetch_results(pick)
    end

    def Stats_db.insertMethod(con, file_id, method_counter)
        pick = con.prepare("INSERT INTO #{METHOD} (#{FILE_REFERENCE}, #{NEW_METHODS}, #{DELETED_METHODS}, #{MODIFIED_METHODS}) VALUES (?, ?, ?, ?)")

        pick.execute(file_id, method_counter['+'], method_counter['-'], method_counter['~'])

        return Utility.toInteger(pick.insert_id)
    end

    def Stats_db.insertMethodStatement(con, file_id, statement_counter)
        pick = con.prepare("INSERT INTO #{METHOD_STATEMENT} (#{FILE_REFERENCE}, #{NEW_CODE}, #{NEW_COMMENT}, #{REMOVED_CODE}, #{REMOVED_COMMENT}, #{MODIFIED_CODE_ADDED}, #{MODIFIED_COMMENT_ADDED}, #{MODIFIED_CODE_DELETED}, #{MODIFIED_COMMENT_DELETED}) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")

        pick.execute(file_id, statement_counter.new_method['code'], statement_counter.new_method['comment'], statement_counter.deleted_method['code'], statement_counter.deleted_method['comment'], statement_counter.modified_method['code_added'], statement_counter.modified_method['comment_added'], statement_counter.modified_method['code_deleted'], statement_counter.modified_method['comment_deleted'])

        return Utility.toInteger(pick.insert_id)
    end

    def Stats_db.getFileCommitPercent(con, repo_owner, repo_name)

        #size_pick = con.prepare
        size_of_commits = "SELECT COUNT(c.#{COMMIT_ID}) FROM #{REPO} AS r INNER JOIN #{COMMITS} AS c ON r.#{REPO_ID} = c.#{REPO_REFERENCE} WHERE r.#{REPO_NAME} LIKE ? AND r.#{REPO_OWNER} LIKE ?"

        #SELECT count(*) from github_data.repositories as r INNER JOIN github_data.commits as c ON r.repo_id = c.repo_reference WHERE r.repo_name LIKE 'acra' AND r.repo_owner LIKE 'ACRA'


        pick = con.prepare("SELECT f.#{PATH}, f.#{NAME}, (COUNT(c.#{COMMIT_ID})/ (#{size_of_commits}) ) * 100 as file_percent, MIN(c.#{COMMIT_DATE}) as #{FIRST_COMMIT}, MAX(c.#{COMMIT_DATE}) as #{LAST_COMMIT} FROM #{REPO} AS r INNER JOIN #{COMMITS} AS c ON r.#{REPO_ID} = c.#{REPO_REFERENCE} INNER JOIN #{FILE} AS f ON c.#{COMMIT_ID} = f.#{COMMIT_REFERENCE} WHERE r.#{REPO_NAME} LIKE ? AND r.#{REPO_OWNER} LIKE ? GROUP BY f.#{PATH}, f.#{NAME} ORDER BY file_percent DESC")

        pick.execute(repo_name, repo_owner, repo_name, repo_owner)

        return Utility.fetch_associated(pick)
    end

    def Stats_db.getCommitMessages(con, repo_owner, repo_name)

        pick = con.prepare("SELECT c.#{COMMIT_ID}, c.#{BODY} FROM #{REPO} AS r INNER JOIN #{COMMITS} AS c ON r.#{REPO_ID} = c.#{REPO_REFERENCE} INNER JOIN #{FILE} AS f ON c.#{COMMIT_ID} = f.#{COMMIT_REFERENCE} INNER JOIN #{METHOD} as m ON f.#{FILE_ID} = m.#{FILE_REFERENCE} WHERE r.#{REPO_NAME} LIKE ? AND r.#{REPO_OWNER} LIKE ? GROUP BY c.#{COMMIT_ID}")

        pick.execute(repo_name, repo_owner)

        return Utility.fetch_associated(pick)
    end

    def Stats_db.getAllRepoMonthAverage(con)

        pick = con.prepare("SELECT r.repo_name, r.repo_owner, AVG(m.new_methods) as #{AVERAGE_METHODS_ADDED}, AVG(m.deleted_methods) as #{AVERAGE_DELETED_METHODS}, AVG(m.modified_methods) as #{AVERAGE_METHODS_MODIFIED} FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference INNER JOIN method as m ON f.file_id = m.file_reference WHERE m.new_methods + m.deleted_methods + m.modified_methods != 0 GROUP BY r.repo_name, r.repo_owner")

        pick.execute

        return Utility.fetch_associated(pick)
    end    

    def Stats_db.getImportantFilesByMethod(con, repo_owner, repo_name, avg_new_methods, avg_deleted_methods, avg_modified_methods)

        #DATE_FORMAT(c.commit_date, '%Y-%m')

        pick = con.prepare("SELECT f.path, f.name, c.commit_id, AVG(m.new_methods) as #{AVERAGE_METHODS_ADDED}, AVG(m.deleted_methods) as #{AVERAGE_DELETED_METHODS}, AVG(m.modified_methods) as #{AVERAGE_METHODS_MODIFIED} FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference INNER JOIN method as m ON f.file_id = m.file_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? GROUP BY f.path, f.name, c.commit_id HAVING #{AVERAGE_METHODS_ADDED} > ? OR #{AVERAGE_DELETED_METHODS} > ? OR #{AVERAGE_METHODS_MODIFIED} > ?")

        pick.execute(repo_name, repo_owner, avg_new_methods, avg_deleted_methods, avg_modified_methods)

        return Utility.fetch_associated(pick)
    end
end