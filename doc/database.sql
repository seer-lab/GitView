/*
 * Use these commands in the admin account for mysql to create the use that is
 * used by the database_interface.
 */
CREATE DATABASE github_data;

CREATE USER 'git_miner'@'localhost' IDENTIFIED BY 'pickaxe';

GRANT ALL ON github_data.* to 'git_miner'@'localhost';

/*
 * The commands for creating all the tables.
 */

/**
 * The create table command for the repositories retrieved
 */
CREATE TABLE repositories
(
    repo_id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    repo_name VARCHAR(64),
    repo_owner VARCHAR(64)
);

/**
 * The create table command for users retrieved from github
 * Users can be authors or commiters
 */
CREATE TABLE users
(
    user_id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(64),
    date DATETIME
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
    body TEXT,
    sha_hash VARCHAR(64)
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
    parent_sha VARCHAR(64)
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
    deletion INTEGER DEFAULT 0,
    patch LONGBLOB,
    file LONGBLOB
);

CREATE TABLE tags
(
    tag_id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    commit_reference BIGINT UNSIGNED REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE,
    tag_name TEXT,
    tag_description TEXT,
    tag_date DATETIME
);

/*
 * The commands for dropping the tables.
 */
DROP TABLE tags;
DROP TABLE file;
DROP TABLE parent_commits;
DROP TABLE commits;
DROP TABLE users;
DROP TABLE repositories;
