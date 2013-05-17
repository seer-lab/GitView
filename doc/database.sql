CREATE DATABASE github_data;

CREATE USER 'git_miner'@'localhost' IDENTIFIED BY 'pickaxe';

GRANT ALL ON github_data.* to 'git_miner'@'localhost';


/**
 * The create table command for the repositories retrieved
 */
CREATE TABLE repositories
(
	repo_id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	repo_name VARCHAR(64)
);

/**
 * The create table command for users retrieved from github
 * Users can be authors or commiters
 */
CREATE TABLE users
(
	user_id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(64),
	date DATE
);


/**
 * The create table command for
 */
/*CREATE TABLE files
(
	files_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY

)*/

/**
 * The create table command for commits retrieved
 */
CREATE TABLE commits
(
	commit_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	repo_reference INTEGER UNSIGNED REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE,
	commiter_reference INTEGER UNSIGNED REFERENCES users (users_id) ON DELETE CASCADE ON UPDATE CASCADE,
	author_reference INTEGER UNSIGNED REFERENCES users (users_id) ON DELETE CASCADE ON UPDATE CASCADE,
	body TEXT
);



/**
 * The create table command for helping store the tree structure of the commits
 * Parents are commits whose children come directly after them in the branch.
 * However children are the ones who know about their parents (parents do not
 * know their children)
 */
CREATE TABLE parent_commits
(
	node_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	children_id BIGINT UNSIGNED REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE,
	parent_id BIGINT UNSIGNED REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE
);

/**
 * The create table command for store the message that was given with the commit
 * Since you can have a title and body but do not have to both are stored in the
 * 'body' the title is very easy to extract the title if needed.
 */
/*CREATE TABLE commit_message
(
	message_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	title TEXT
	body TEXT
)*/

/**
 * The create table command for 
 */
CREATE TABLE file
(
	file_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	commit_reference BIGINT UNSIGNED REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE,
	name TEXT,
	addition INTEGER DEFAULT 0,
	deletions INTEGER DEFAULT 0,
	patch LONGTEXT,
	file LONGTEXT
);