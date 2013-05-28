require 'mysql'

DATABASE = 'github_data'
HOST = 'localhost'
USERNAME = 'git_miner'
PASSWORD = 'pickaxe'

#Tables:
REPO = 'repositories'
USERS = 'users'
COMMITS = 'commits'
PARENT_COMMITS = 'parent_commits'
FILE = 'file'
TAGS = 'tags'
FILE_TYPE = 'file_types'
REPO_FILE_TYPE = 'repo_file_types'

# Drop table commands
DROP_REPO = 'DROP TABLE repositories'
DROP_USER = 'DROP TABLE users'
DROP_COMMITS = 'DROP TABLE commits'
DROP_PARENTS = 'DROP TABLE parent_commits'
DROP_FILE = 'DROP TABLE file'
DROP_TAGS = 'DROP TABLE tags'

# Column Names
# Repo
REPO_ID = 'repo_id'
REPO_NAME = 'repo_name'
REPO_OWNER = 'repo_owner'

# User
USER_ID = 'user_id'
NAME = 'name'
DATE = 'date'

# Commits
COMMIT_ID = 'commit_id'
REPO_REFERENCE ='repo_reference'
COMMITER_REFERENCE = 'commiter_reference'
AUTHOR_REFERENCE = 'author_reference'
BODY = 'body'
SHA = 'sha_hash'

# Parent Commits
NODE_ID = 'node_id'
CHILDREN_ID = 'children_id'
PARENT_ID = 'parent_sha'

# File
FILE_ID = 'file_id'
COMMIT_REFERENCE = 'commit_reference'
#NAME = 'name'
ADDITION = 'addition'
DELETION = 'deletion'
PATCH = 'patch'

# Tags
TAG_ID = 'tag_id'
#COMMIT_REFERENCE = 'commit_reference'
TAG_NAME = 'tag_name'
TAG_DESC = 'tag_description'
TAG_DATE = 'tag_date'

# File_types
TYPE_ID = 'type_id'
TYPE = 'type'

# Repo file types
#REPO_ID = 'repo_id'
FILE_TYPE_ID = 'file_type_id'

EXTENSION_EXPRESSION = '%\.'

#con = Mysql.new(HOST, USERNAME, PASSWORD, DATABASE)

=begin
begin
    con = Mysql.new(HOST, USERNAME, PASSWORD, DATABASE)
    rs = con.prepare("SELECT * FROM #{REPO}")
    rs.execute
    rs.num_rows.times do
        result = rs.fetch
        result.each { |x| puts x }
    end

rescue Mysql::Error => e
    puts e.errno
    puts e.error

ensure
    con.close if con
end
=end

class User
    def initialize(repo_name, date)
        @repo_name = repo_name
        @date = date
    end

    def name()
        @repo_name
    end

    def date()
        @date
    end
end

class Commit
    def initialize(repo, commiter, author, body, sha)
        @repo = repo
        @commiter = commiter
        @author = author
        @body = body
        @sha = sha
    end

    def repo()
        @repo
    end

    def commiter()
        @commiter
    end

    def author()
        @author
    end

    def body()
        @body
    end

    def sha()
        @sha
    end
end

class Sourcefile
    def initialize(commit, name, addition, deletion, patch, file)
        @commit = commit
        @name = name
        @addition = addition
        @deletion = deletion
        @patch = patch
        @file = file
    end

    def commit ()
        @commit
    end

    def name ()
        @name
    end

    def addition ()
        @addition
    end

    def deletion ()
        @deletion
    end

    def patch ()
        @patch
    end

    def file ()
        @file
    end
end

class Tag
    def initialize(commit, tag_name, tag_description, tag_date)
        @commit = commit
        @tag_name = tag_name
        @tag_description = tag_description
        @tag_date = tag_date
    end

    def commit()
        @commit        
    end

    def tag_name()
        @tag_name
    end

    def tag_description()
        @tag_description
    end

    def tag_date()
        @tag_date        
    end
end

def createConnection()
    Mysql.new(HOST, USERNAME, PASSWORD, DATABASE)
end

# Get all the repositories stored in the database
# Params:
# +con+:: the database connection used. 
def getRepos(con)
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

# Get the repository's id stored in the database with the given name
# Params:
# +con+:: the database connection used. 
# +name+:: the name of the repository
def getRepoId(con, name, owner)
    pick = con.prepare("SELECT #{REPO_ID} FROM #{REPO} WHERE #{REPO_NAME} LIKE ? AND #{REPO_OWNER} LIKE ?")
    pick.execute(name, owner)

    result = pick.fetch

    if(result == nil)
        result = insertRepo(con, name, owner)
    end
    #There should be only 1 id return anyways.
    return result
end    

# Insert the given repository to the database
# +con+:: the database connection used. 
# +repo+:: the name of the repository
def insertRepo(con, repo, owner)
    pick = con.prepare("INSERT INTO #{REPO} (#{REPO_NAME}, #{REPO_OWNER}) VALUES (?, ?)")
    pick.execute(repo, owner)

    return toInteger(pick.insert_id)
end

# Update the repository in the database
# +con+:: the database connection used. 
# +id+:: the id of the repository
# +repo+:: the new name
#def updateRepo(con, id, repo)
#    pick = con.prepare("UPDATE #{REPO} SET #{REPO_NAME}=? WHERE #{REPO_ID}=?")
#    pick.execute(repo, id)
#end

# Get all the users stored in the database
# Params:
# +con+:: the database connection used. 
def getUsers(con)
    pick = con.prepare("SELECT * FROM #{USERS}")
    pick.execute

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    #results.each { |x| puts x }
    return results
end

# Get all the users stored in the database
# Params:
# +con+:: the database connection used.
# +user+:: the user entry into the datase 
def getUserId(con, user)
    pick = con.prepare("SELECT #{USER_ID} FROM #{USERS} WHERE #{NAME}=? AND #{DATE}=?")
    pick.execute(user.name, user.date)

    result = pick.fetch

    #puts "result #{result}"
    if(result == nil)
        result = insertUser(con, user)
    end
    #puts "#{user.name} id = #{result}"

    return result
end

# Insert the given user to the database
# +con+:: the database connection used. 
# +user+:: the name of the repository
def insertUser(con, user)
    pick = con.prepare("INSERT INTO #{USERS} (#{NAME}, #{DATE}) VALUES (?, ?)")
    pick.execute(user.name, user.date)

    return toInteger(pick.insert_id)
end

# Update the user in the database
# +con+:: the database connection used. 
# +id+:: the id of the repository
# +user+:: the new name
=begin
def updateUser(con, id, repo)
    pick = con.prepare("UPDATE #{USERS} SET #{NAME}=?,#{DATE}=? WHERE #{REPO_ID}=?")
    pick.execute(repo, id);
end
=end

# Get all the commits stored in the database
# Params:
# +con+:: the database connection used. 
def getCommits(con)
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
# +commit+:: the +Commit+ with:
#     - +repo_name+:: the name of the repository
#     - +commiter+:: the +User+ that committed the commit
#     - +author+:: the +User+ that wrote the code that is part of this commit
#     - +body+:: the commit message
#     - +sha+:: the uuid for the commit
def insertCommits(con, commit)

    repo_id = getRepoId(con, commit.repo)
    commiter_id = getUserId(con, commit.commiter)
    author_id = getUserId(con, commit.author)

    pick = con.prepare("INSERT INTO #{COMMITS} (#{REPO_REFERENCE}, #{COMMITER_REFERENCE}, #{AUTHOR_REFERENCE}, #{BODY}, #{SHA}) VALUES (?, ?, ?, ?, ?)")
    pick.execute(repo_id, commiter_id, author_id, commit.body, commit.sha)

    return toInteger(pick.insert_id)
end

# Insert the given commits to the database, with the ids already given.
# +con+:: the database connection used. 
# +commit+:: the +Commit+ with:
#     - +repo_id+:: the id of the repository
#     - +commiter_id+:: the id of the user that committed the commit
#     - +author_id+:: the id of the user that wrote the code that is part of this commit
#     - +body+:: the commit message
#     - +sha+:: the uuid for the commit
def insertCommitsIds(con, commit)

    pick = con.prepare("INSERT INTO #{COMMITS} (#{REPO_REFERENCE}, #{COMMITER_REFERENCE}, #{AUTHOR_REFERENCE}, #{BODY}, #{SHA}) VALUES (?, ?, ?, ?, ?)")
    #puts "repoid = #{commit.repo}"
    #puts "commiterid = #{commit.commiter}"
    #puts "authorid = #{commit.author}"
    #puts "body = #{commit.body}"
    #puts "sha = #{commit.sha}"
    pick.execute(commit.repo, commit.commiter, commit.author, commit.body, commit.sha)

    return toInteger(pick.insert_id)
end

# Get the commit id If the commit is not found it will be added to the db
# +con+:: the database connection used. 
# +commit+:: the +Commit+ with:
#     - +repo_name+:: the name of the repository
#     - +commiter+:: the +User+ that committed the commit
#     - +author+:: the +User+ that wrote the code that is part of this commit
#     - +body+:: the commit message
#     - +sha+:: the uuid for the commit
def getCommitId(con, sha)

    pick = con.prepare("SELECT #{COMMIT_ID} FROM #{COMMITS} WHERE #{SHA}=?")

    #puts "sha = #{sha}"
    pick.execute(sha)

    return toInteger(pick.fetch)
end

# Insert the given commits to the database
# +con+:: the database connection used. 
# +child_commit+:: the +Commit+ of the child
# +parent_commit+:: the +Commit+ of the parent
def insertParent(con, child_commit, parent_commit)

    #child_id = getCommitSha(con, child_commit.sha)
    #parent_id = getCommitId(con, parent_commit)

    pick = con.prepare("INSERT INTO #{PARENT_COMMITS} (#{CHILDREN_ID}, #{PARENT_ID}) VALUES (?, ?)")

    pick.execute(child_commit, parent_commit)

    return toInteger(pick.insert_id)
end

# Get all the parents of a given child commit
# +con+:: the database connection used. 
# +child_id+:: the id of the child commit
def getParents(con, child_id)

    pick = con.prepare("SELECT c1.#{REPO_REFERENCE}, c1.#{COMMITER_REFERENCE}, c1.#{AUTHOR_REFERENCE}, c1.#{BODY}, c1.#{SHA} FROM #{PARENT_COMMMITS} AS p1 INNER JOIN #{COMMITS} AS c1 ON p1.#{PARENT_ID} = c1.#{SHA}, #{COMMITS} AS c2 WHERE c2.#{COMMIT_ID}=?")

    pick.execute(child_id)

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end

# Insert the file into the database
# +con+:: the database connection used.
# +file+:: the +File+ to be added to the database.
def insertFile(con, file)

    commit_id = getCommitId(con, file.commit)

    pick = con.prepare("INSERT INTO #{FILE} (#{COMMIT_REFERENCE}, #{NAME}, #{ADDITION}, #{DELETION}, #{PATCH}, #{FILE}) VALUES (?, ?, ?, ?, ?, ?)")
    pick.execute(commit_id, file.name, file.addition, file.deletion, file.patch, file.file)

    return toInteger(pick.insert_id)
end

# Insert the file into the database with the commit id already provided
# +con+:: the database connection used.
# +file+:: the +File+ to be added to the database.
def insertFileId(con, file)

    pick = con.prepare("INSERT INTO #{FILE} (#{COMMIT_REFERENCE}, #{NAME}, #{ADDITION}, #{DELETION}, #{PATCH}, #{FILE}) VALUES (?, ?, ?, ?, ?, ?)")
    pick.execute(file.commit, file.name, file.addition, file.deletion, file.patch, file.file)

    return toInteger(pick.insert_id)
end


# Get all the files that are related to the given commit
# +con+:: the database connection used. 
# +commit_id+:: the id of a commit
def getCommitFiles(con, commit_id)


    pick = con.prepare("SELECT * FROM #{FILE} WHERE #{COMMIT_REFERENCE} = ?")
    pick.execute(commit_id)

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end

# Insert the given tag into the database
# +con+:: the database connection used. 
# +tag+:: the +Tag+ containing all the relatvent information about the tag.
def insertTag(con, tag)
    commit_id = getCommitId(con, tag.commit)

    pick = con.prepare("INSERT INTO #{TAGS} (#{COMMIT_REFERENCE}, #{TAG_NAME}, #{TAG_DESC}, #{TAG_DATE}) VALUES (?, ?, ?, ?)")
    pick.execute(commit_id, tag.tag_name, tag.tag_description, tag.tag_date)
 
    return toInteger(pick.insert_id)
end

# Get all the tags in the database
# +con+:: the database connection used. 
def getTags(con)


    pick = con.prepare("SELECT * FROM #{TAGS}")
    
    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end


def toInteger(array)
    if array.class.name == Array.to_s
        #puts "is_array"
        return array[0]
    else
        return array
    end
end

def setFileTypes(con, repo_name, repo_owner)
    pick = con.prepare("SELECT #{TYPE}, #{TYPE_ID} FROM #{FILE_TYPE}")

    pick.execute

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch

        pick2 = con.prepare("SELECT DISTINCT #{REPO_ID} FROM #{REPO} AS r INNER JOIN #{COMMITS} AS c ON r.#{REPO_ID} = c.#{REPO_REFERENCE} INNER JOIN #{FILE} AS f ON c.#{COMMIT_ID} = f.#{COMMIT_REFERENCE} WHERE r.#{REPO_NAME} LIKE ? AND r.#{REPO_OWNER} LIKE ? AND f.#{NAME} LIKE ?")
        pick2.execute(repo_name, repo_owner, "#{EXTENSION_EXPRESSION}#{results[x][0]}")

        rows2 = pick2.num_rows

        if rows2 > 0 
            putter = con.prepare("INSERT INTO #{REPO_FILE_TYPE} (#{REPO_ID}, #{FILE_TYPE_ID}) VALUES (?, ?)")
            putter.execute(pick2.fetch[0], results[x][1])
        end
    end

end

def getFileTypes(con, repo_name, repo_owner)
    pick = con.prepare("SELECT #{TYPE} FROM #{FILE_TYPE} AS ft INNER JOIN #{REPO_FILE_TYPE} AS rf ON ft.#{TYPE_ID} = rf.#{FILE_TYPE_ID} INNER JOIN #{REPO} AS r ON rf.#{REPO_ID} = r.#{REPO_ID} WHERE r.REPO_NAME LIKE ? AND r.#{REPO_OWNER} LIKE ?")

    pick.execute(repo_name, repo_owner)

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end