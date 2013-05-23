SELECT c1.* FROM parent_commits AS p1 INNER JOIN commits AS c1 ON p1.parent_id = c1.commit_id, commits AS c2 WHERE c2.commit_id=2;

SELECT r.repo_name, com.name, com.date, aut.name, c1.body, c1.sha_hash
FROM repositories AS r INNER JOIN commits AS c1 ON r.repo_id = c1.repo_reference INNER JOIN users AS com ON c1.commiter_reference = com.user_id INNER JOIN
	users AS aut ON c1.author_reference = aut.user_id;

/*
 * Gets all the files that are python
 */
SELECT file FROM file AS f INNER JOIN commits AS c ON f.commit_reference = c.commit_id INNER JOIN repositories AS r ON c.repo_reference = r.repo_id WHERE name LIKE '%\.py'

# Extention of your choice
#SELECT file FROM file AS f INNER JOIN commits AS c ON f.commit_reference = c.commit_id INNER JOIN repositories AS r ON c.repo_reference = r.repo_id WHERE name LIKE '%\.#{file_extention}'

SELECT c.sha_hash, f.file, com.date FROM file AS f INNER JOIN commits AS c ON f.commit_reference = c.commit_id INNER JOIN users AS aut ON c.author_reference = aut.user_id INNER JOIN users AS com ON c.commiter_reference = com.user_id INNER JOIN repositories AS r ON c.repo_reference = r.repo_id WHERE f.name LIKE '%\.py' ORDER BY com.date


/*
 * Get all files from 1 commit.
 */
SELECT c.sha_hash, f.file, com.date FROM file AS f INNER JOIN commits AS c ON f.commit_reference = c.commit_id INNER JOIN users AS aut ON c.author_reference = aut.user_id INNER JOIN users AS com ON c.commiter_reference = com.user_id INNER JOIN repositories AS r ON c.repo_reference = r.repo_id WHERE f.name LIKE '%\.py' AND c.sha_hash = '056055f316ae660880c8262feb29ccd4e2bc1191' ORDER BY com.date

/*
 *
 */
SELECT f.name, f.file, com.date FROM file AS f INNER JOIN commits AS c ON f.commit_reference = c.commit_id INNER JOIN users AS aut ON c.author_reference = aut.user_id INNER JOIN users AS com ON c.commiter_reference = com.user_id INNER JOIN repositories AS r ON c.repo_reference = r.repo_id WHERE f.name LIKE '%\.py' AND c.sha_hash = '056055f316ae660880c8262feb29ccd4e2bc1191' ORDER BY com.date

SELECT f.name, f.file, com.date FROM file AS f INNER JOIN commits AS c ON f.commit_reference = c.commit_id INNER JOIN users AS aut ON c.author_reference = aut.user_id INNER JOIN users AS com ON c.commiter_reference = com.user_id INNER JOIN repositories AS r ON c.repo_reference = r.repo_id WHERE f.name LIKE '%\.py' AND com.date < '2011-11-22 23:59:58' ORDER BY com.date DESC

SELECT c.* FROM commits AS c INNER JOIN repositories AS r ON c.repo_reference = r.repo_id;

# Get the repo_ids
SELECT repo_id FROm repositories;

#Iterate through each repo getting all the commits related to the repo
SELECT commit_id FROM commits WHERE repo_reference = {the_repo_id}
ex.
SELECT commit_id FROM commits WHERE repo_reference = 1

#Iterate through all commits
SELECT file FROM file WHERE commit_reference = {commit_id}
ex.
SELECT file_name file FROM file WHERE commit_reference = 1

#From the files i
SELECT name, patch FROM file WHERE commit_reference = 413 AND name LIKE '%\.py'

SELECT c.commit_id FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference WHERE r.repo_name LIKE 'spotify' AND r.repo_owner LIKE 'luigi'