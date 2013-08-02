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
    repo_id INTEGER UNSIGNED AUTO_INCREMENT,
    repo_name VARCHAR(64),
    repo_owner VARCHAR(64),
    PRIMARY KEY(repo_id)
);

/**
 * The create table command for users retrieved from github
 * Users can be authors or commiters
 */
CREATE TABLE users
(
    user_id INTEGER UNSIGNED AUTO_INCREMENT,
    name VARCHAR(64),
    date DATETIME,
    PRIMARY KEY(user_id)
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
    commit_id BIGINT UNSIGNED AUTO_INCREMENT,
    repo_reference INTEGER UNSIGNED,
    commiter_reference INTEGER UNSIGNED,
    author_reference INTEGER UNSIGNED,
    body TEXT,
    sha_hash VARCHAR(64),
    PRIMARY KEY (commit_id),
    CONSTRAINT fkey_commits_1 FOREIGN KEY (repo_reference) REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fkey_commits_2 FOREIGN KEY (commiter_reference) REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fkey_commits_3 FOREIGN KEY (author_reference) REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE
);



/**
 * The create table command for helping store the tree structure of the commits
 * Parents are commits whose children come directly after them in the branch.
 * However children are the ones who know about their parents (parents do not
 * know their children)
 */
CREATE TABLE parent_commits
(
    node_id BIGINT UNSIGNED AUTO_INCREMENT,
    children_id BIGINT UNSIGNED,
    parent_sha VARCHAR(64),
    PRIMARY KEY (node_id),
    CONSTRAINT fkey_parent_1 FOREIGN KEY (children_id) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE
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
    commit_reference BIGINT UNSIGNED,
    name TEXT,
    addition INTEGER DEFAULT 0,
    deletion INTEGER DEFAULT 0,
    patch LONGBLOB,
    file LONGBLOB,
    CONSTRAINT fkey_file_1 FOREIGN KEY (commit_reference) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE tags
(
    tag_id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    repo_reference INTEGER UNSIGHED,
    commit_reference BIGINT UNSIGNED,
    tag_name TEXT,
    tag_description TEXT,
    tag_date DATETIME, 
    CONSTRAINT fkey_tags_1 FOREIGN KEY (commit_reference) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fkey_tags_2 FOREIGN KEY (repo_reference) REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE
);

/* Will store 'py', 'rb', 'java'... */
CREATE TABLE file_types
(
    type_id INTEGER UNSIGNED AUTO_INCREMENT,
    type VARCHAR(16),
    PRIMARY KEY(type_id)
);

CREATE TABLE repo_file_types
(
    repo_id INTEGER UNSIGNED,
    file_type_id INTEGER UNSIGNED,
    CONSTRAINT fkey_repo_file_1 FOREIGN KEY (repo_id) REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fkey_repo_file_2 FOREIGN KEY (file_type_id) REFERENCES file_types (type_id) ON DELETE CASCADE ON UPDATE CASCADE
);


INSERT INTO file_types (type) VALUES ('py'),('rb'),('java');
/*
 * The commands for dropping the tables.
 */
DROP TABLE file_types;
DROP TABLE repo_file_types;
DROP TABLE tags;
DROP TABLE file;
DROP TABLE parent_commits;
DROP TABLE commits;
DROP TABLE users;
DROP TABLE repositories;

/*
 * Use to update github_data tables that were created using old schema
 */ 
ALTER TABLE commits ADD CONSTRAINT fkey_commits_1 FOREIGN KEY (repo_reference) REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE, ADD CONSTRAINT fkey_commits_2 FOREIGN KEY (commiter_reference) REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE, ADD CONSTRAINT fkey_commits_3 FOREIGN KEY (author_reference) REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE parent_commits ADD CONSTRAINT fkey_parent_1 FOREIGN KEY (children_id) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE file ADD CONSTRAINT fkey_file_1 FOREIGN KEY (commit_reference) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE tags ADD CONSTRAINT fkey_tags_1 FOREIGN KEY (commit_reference) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE repo_file_types ADD CONSTRAINT fkey_repo_file_1 FOREIGN KEY (repo_id) REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE, ADD CONSTRAINT fkey_repo_file_2 FOREIGN KEY (file_type_id) REFERENCES file_types (type_id) ON DELETE CASCADE ON UPDATE CASCADE;