CREATE DATABASE tagged_comments;

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
    body TEXT,
    PRIMARY KEY(commit_id),
    CONSTRAINT fkey_commits_1 FOREIGN KEY (repo_reference) REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE
    /*Might be useful to have the body and the sha of the commit as well */
);

CREATE TABLE file
(
    file_id BIGINT UNSIGNED AUTO_INCREMENT,
    commit_reference BIGINT UNSIGNED,
    path TEXT,
    name TEXT,
    PRIMARY KEY(file_id),
    CONSTRAINT fkey_file_1 FOREIGN KEY (commit_reference) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE statement
(
    statement_id BIGINT UNSIGNED AUTO_INCREMENT,
    file_reference BIGINT UNSIGNED,
    /* This is used to organize the blocks of code/comment */
    block_number INT UNSIGNED,
    /* Implied foreign key to statement_id */
    parent_reference BIGINT UNSIGNED,
    /*value TEXT,*/
    type VARCHAR(32),
    comment TEXT,
    actualValue TEXT,
    PRIMARY KEY(statement_id),
    CONSTRAINT fkey_statement_1 FOREIGN KEY (file_reference) REFERENCES file (file_id) ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE repositories;
DROP TABLE commits;
DROP TABLE file;

INSERT INTO repositories (repo_name, repo_owner) VALUES ('test', 'tester');

INSERT INTO commits (repo_reference, commit_date, body) VALUES (1, '2013-09-07 12:32:12', "test commit 1");

INSERT INTO file (commit_reference, path, name) VALUES (1, 'forIn.java', 'forIn.java');

INSERT INTO statement (file_reference, parent_reference, type, comment, actualValue) VALUES (1, NULL, 'class', '// For the each of the many', 'public class forIn');

INSERT INTO statement (file_reference, parent_reference, type, comment, actualValue) VALUES (1, 1, 'var_declaration', '// member declaration', 'public static final int numberOfRuns = 6;');

SELECT s2.* FROM statement AS s1 INNER JOIN statement AS s2 ON s1.statement_id = s2.parent_reference;