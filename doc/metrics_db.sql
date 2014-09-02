CREATE DATABASE metrics;

GRANT ALL ON metrics.* to 'git_miner'@'localhost';

USE metrics;

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
    project_name VARCHAR(64),
    sha_hash VARCHAR(64),
    commit_date DATETIME,
    PRIMARY KEY(commit_id),
    CONSTRAINT fkey_commits_1 FOREIGN KEY (repo_reference) REFERENCES repositories (repo_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE method
(
    method_id BIGINT UNSIGNED AUTO_INCREMENT,
    commit_reference BIGINT UNSIGNED,
    method_name TEXT,
    number_method_line INTEGER,
    nested_block_depth INTEGER,
    cyclomatic_complexity INTEGER,
    number_parameters INTEGER,
    PRIMARY KEY(method_id),
    CONSTRAINT fk_method_1 FOREIGN KEY (commit_reference) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE class
(
    class_id BIGINT UNSIGNED AUTO_INCREMENT,
    commit_reference BIGINT UNSIGNED,
    class_name TEXT,
    inheritance_depth INTEGER,
    weighted_methods INTEGER,
    children_count INTEGER,
    overridden_methods INTEGER,
    lack_cohesion_methods DOUBLE,
    attribute_count INTEGER,
    static_attribute_count INTEGER,
    method_count INTEGER,
    static_method_count INTEGER,
    specialization_index DOUBLE,
    PRIMARY KEY (class_id),
    CONSTRAINT fk_class_1 FOREIGN KEY (commit_reference) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE package
(
    package_id BIGINT UNSIGNED AUTO_INCREMENT,
    commit_reference BIGINT UNSIGNED,
    package_name TEXT,
    afferent_coupling INTEGER,
    efferent_coupling INTEGER,
    instability DOUBLE,
    abstractness DOUBLE,
    normalized_distance DOUBLE,
    classes_number INTEGER,
    interfaces_number INTEGER,
    PRIMARY KEY(package_id),
    CONSTRAINT fk_package_1 FOREIGN KEY (commit_reference) REFERENCES commits (commit_id) ON DELETE CASCADE ON UPDATE CASCADE
);

/*
DROP TABLE package;
DROP TABLE class;
DROP TABLE method;
DROP TABLE commits;
DROP TABLE repositories;
*/