CREATE DATABASE project_stats;

GRANT ALL ON project_stats.* to 'git_miner'@'localhost';

/**
 * The create table command for the repositories retrieved
 */
CREATE TABLE repositories
(
    repo_id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    repo_name VARCHAR(64),
    repo_owner VARCHAR(64)
);

CREATE TABLE commits
(
    commit_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    repo_reference INTEGER UNSIGNED REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE,
    commit_date DATETIME,
    body TEXT,/*
    total_comments INT,
    total_code INT,*/
    total_comment_addition INT,
    total_comment_deletion INT,
    total_code_addition INT,
    total_code_deletion INT
    /*Might be useful to have the body and the sha of the commit as well */
);

CREATE TABLE file
(
    file_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    commit_reference BIGINT UNSIGNED REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE,
    path TEXT,
    name TEXT,/*
    num_comments INT,
    num_code INT,*/
    comment_addition INT,
    comment_deletion INT,
    code_addition INT,
    code_deletion INT
);

DROP TABLE repositories;
DROP TABLE commits;
DROP TABLE file;

INSERT INTO commits (repo_reference, commit_date, body, total_comments, total_code) VALUES (1, '09-06-2013', "fdsjafdsjokfj", 1, 2)
