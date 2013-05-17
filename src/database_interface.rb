require 'mysql'

DATABASE = 'github_data'
HOST = 'localHOST'
USERNAME = 'git_miner'
PASSWORD = 'pickaxe'

#Tables:
REPO = 'repositories'
USERS = 'users'
COMMITS = 'commits'
PARENT_COMMITS = 'parent_commits'
FILE = 'file'

# Drop table commands
DROP_REPO = 'DROP TABLE repositories'
DROP_USER = 'DROP TABLE users'
DROP_COMMITS = 'DROP TABLE commits'
DROP_PARENTS = 'DROP TABLE parent_commits'
DROP_FILE = 'DROP TABLE file'

# Column Names
# Repo
REPO_ID = 'repo_id'
REPO_NAME = 'repo_name'

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
PARENT_ID = 'parent_id'

# File
FILE_ID = 'file_id'
COMMIT_REFERENCE = 'commit_reference'
ADDITION = 'addition'
DELETION = 'deletion'
PATCH = 'patch'
FILE = 'file'

con = Mysql.new(HOST, USERNAME, PASSWORD, DATABASE)

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
def getRepoId(con, name)
	pick = con.prepare("SELECT #{REPO_ID} FROM #{REPO} WHERE #{REPO_NAME} LIKE ?")
	pick.execute(name)

	result = pick.fetch

	if(result == nil)
		result = insertRepo(con, name)
	end
	#There should be only 1 id return anyways.
	return result
end	

# Insert the given repository to the database
# +con+:: the database connection used. 
# +repo+:: the name of the repository
def insertRepo(con, repo)
	pick = con.prepare("INSERT INTO #{REPO} (repo_name) VALUES (?)")
	pick.execute(repo)

	return pick.insert_id
end

# Update the repository in the database
# +con+:: the database connection used. 
# +id+:: the id of the repository
# +repo+:: the new name
def updateRepo(con, id, repo)
	pick = con.prepare("UPDATE #{REPO} SET #{REPO_NAME}=? WHERE #{REPO_ID}=?")
	pick.execute(repo, id)
end

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

	if(result == nil)
		result = insertUser(con, user)
	end

	return results
end

# Insert the given user to the database
# +con+:: the database connection used. 
# +user+:: the name of the repository
def insertUser(con, user)
	pick = con.prepare("INSERT INTO #{USERS} (#{NAME}, #{DATE}) VALUES (?, ?)")
	pick.execute(user.name, user.date)

	return pick.insert_id
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
# 	- +repo_name+:: the name of the repository
# 	- +commiter+:: the +User+ that committed the commit
# 	- +author+:: the +User+ that wrote the code that is part of this commit
# 	- +body+:: the commit message
# 	- +sha+:: the uuid for the commit
def insertCommits(con, commit)

	repo_id = getRepoId(con, commit.repo)
	commiter_id = getUserId(con, commit.commiter)
	author_id = getUserId(con, commit.author)

	pick = con.prepare("INSERT INTO #{COMMITS} (#{REPO_REFERENCE}, #{COMMITER_REFERENCE}, #{AUTHOR_REFERENCE}, #{BODY}, #{SHA}) VALUES (?, ?, ?, ?, ?)")
	pick.execute(repo_id, commiter_id, author_id, commit.body, commit.sha)

	return pick.insert_id
end

# Get the commit id If the commit is not found it will be added to the db
# +con+:: the database connection used. 
# +commit+:: the +Commit+ with:
# 	- +repo_name+:: the name of the repository
# 	- +commiter+:: the +User+ that committed the commit
# 	- +author+:: the +User+ that wrote the code that is part of this commit
# 	- +body+:: the commit message
# 	- +sha+:: the uuid for the commit
def getCommitId(con, commit)

	pick = con.prepare("SELECT #{COMMIT_ID} FROM #{COMMITS} WHERE #{SHA}=?")
	pick.execute(commit.sha)

	result = pick.fetch

	if(result == nil)
		result = insertCommits(con, commit)
	end

	return results
end

# Insert the given commits to the database
# +con+:: the database connection used. 
# +child_commit+:: the +Commit+ of the child
# +parent_commit+:: the +Commit+ of the parent
def insertParent(con, child_commit, parent_commit)

	child_id = getCommitId(con, child_commit)
	parent_id = getCommitId(con, parent_commit)

	pick = con.prepare("INSERT INTO #{PARENT_COMMITS} (#{CHILDREN_ID}, #{PARENT_ID}) VALUES (?, ?)")
	pick.execute(child_id, parent_id)

	return pick.insert_id
end

def getParents(con, child_id)

	pick = con.prepare("SELECT c1.#{REPO_REFERENCE}, c1.#{COMMITER_REFERENCE}, c1.#{AUTHOR_REFERENCE}, c1.#{BODY}, c1.#{SHA} FROM #{PARENT_COMMMITS} AS p1 INNER JOIN #{COMMITS} AS c1 ON p1.#{PARENT_ID} = c1.#{COMMIT_ID}, #{COMMITS} AS c2 WHERE c2.#{COMMIT_ID}=?")

	pick.execute(child_id)

	rows = pick.num_rows
	results = Array.new(rows)

	rows.times do |x|
		results[x] = pick.fetch
	end

	return results
end