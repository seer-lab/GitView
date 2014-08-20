CREATE DATABASE project_stats;

GRANT ALL ON project_stats.* to 'git_miner'@'localhost';

USE project_stats;

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

CREATE TABLE user
(
    user_id BIGINT UNSIGNED AUTO_INCREMENT,
    name VARCHAR(64),
    PRIMARY KEY(user_id)
);

CREATE TABLE commits
(
    commit_id BIGINT UNSIGNED AUTO_INCREMENT,
    repo_reference INTEGER UNSIGNED,
    sha_hash VARCHAR(64),
    commit_date DATETIME,
    committer_id BIGINT UNSIGNED,
    author_id BIGINT UNSIGNED,
    body TEXT,
    total_comments INT,
    total_code INT,
    total_comment_addition INT,
    total_comment_deletion INT,
    total_comment_modified INT,
    total_code_addition INT,
    total_code_deletion INT,
    total_code_modified INT,
    PRIMARY KEY(commit_id),
    CONSTRAINT fkey_commits_1 FOREIGN KEY (repo_reference) REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fkey_commits_2 FOREIGN KEY (committer_id) REFERENCES user (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fkey_commits_3 FOREIGN KEY (author_id) REFERENCES user (user_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE file
(
    file_id BIGINT UNSIGNED AUTO_INCREMENT,
    commit_reference BIGINT UNSIGNED,
    path TEXT,
    name TEXT,
    total_comments INT,
    total_code INT,
    comment_addition INT,
    comment_deletion INT,
    comment_modified INT,
    code_addition INT,
    code_deletion INT,
    code_modified INT,
    PRIMARY KEY(file_id),
    CONSTRAINT fkey_file_1 FOREIGN KEY (commit_reference) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE method
(
    method_id BIGINT UNSIGNED AUTO_INCREMENT,
    file_reference BIGINT UNSIGNED,
    new_methods INT,
    deleted_methods INT,
    modified_methods INT,
    PRIMARY KEY(method_id),
    CONSTRAINT fkey_method_1 FOREIGN KEY (file_reference) REFERENCES file (file_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE method_statement
(
    statement_id BIGINT UNSIGNED AUTO_INCREMENT,
    file_reference BIGINT UNSIGNED,

    new_code INT,
    new_comment INT,

    deleted_code INT,
    deleted_comment INT,

    modified_code_added INT,
    modified_comment_added INT,
    modified_code_deleted INT,
    modified_comment_deleted INT,
    PRIMARY KEY(statement_id),
    CONSTRAINT fkey_statement_1 FOREIGN KEY (file_reference) REFERENCES file (file_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE tags
(
    tag_id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    repo_reference INTEGER UNSIGNED,
    tag_sha VARCHAR(64),
    tag_name TEXT,
    tag_description TEXT,
    tag_date DATETIME,
    commit_sha TEXT, 
    CONSTRAINT fkey_tags_1 FOREIGN KEY (repo_reference) REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE
);

/*
DROP TABLE method_statement;
DROP TABLE method;
DROP TABLE file;
DROP TABLE tags;
DROP TABLE commits;
DROP TABLE user;
DROP TABLE repositories;
*/

/*
INSERT INTO commits (repo_reference, commit_date, body, total_comments, total_code) VALUES (1, '09-06-2013', "fdsjafdsjokfj", 1, 2)
*/
/* 
 * Alter commands to fix databases that were created with the old schema.
 */
/*
ALTER TABLE commits ADD CONSTRAINT fkey_commits_1 FOREIGN KEY (repo_reference) REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE file ADD CONSTRAINT fkey_file_1 FOREIGN KEY (commit_reference) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE;
*/