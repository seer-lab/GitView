CREATE DATABASE project_stats;

GRANT ALL ON project_stats.* to 'git_miner'@'localhost';

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

CREATE TABLE commits
(
    commit_id BIGINT UNSIGNED AUTO_INCREMENT,
    repo_reference INTEGER UNSIGNED,
    commit_date DATETIME,
    body TEXT,/*
    total_comments INT,
    total_code INT,*/
    total_comment_addition INT,
    total_comment_deletion INT,
    total_code_modified INT,
    total_code_addition INT,
    total_code_deletion INT,
    total_comment_modified INT,
    PRIMARY KEY(commit_id),
    CONSTRAINT fkey_commits_1 FOREIGN KEY (repo_reference) REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE
    /*Might be useful to have the body and the sha of the commit as well */
);

CREATE TABLE file
(
    file_id BIGINT UNSIGNED AUTO_INCREMENT,
    commit_reference BIGINT UNSIGNED,
    path TEXT,
    name TEXT,/*
    num_comments INT,
    num_code INT,*/
    comment_addition INT,
    comment_deletion INT,
    comment_modified INT,
    code_addition INT,
    code_deletion INT,
    code_modified INT,
    PRIMARY KEY(file_id),
    CONSTRAINT fkey_file_1 FOREIGN KEY (commit_reference) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE file;
DROP TABLE commits;
DROP TABLE repositories;



INSERT INTO commits (repo_reference, commit_date, body, total_comments, total_code) VALUES (1, '09-06-2013', "fdsjafdsjokfj", 1, 2)

/* 
 * Alter commands to fix databases that were created with the old schema.
 */
ALTER TABLE commits ADD CONSTRAINT fkey_commits_1 FOREIGN KEY (repo_reference) REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE file ADD CONSTRAINT fkey_file_1 FOREIGN KEY (commit_reference) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE;
