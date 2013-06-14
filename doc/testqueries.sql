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
SELECT file FROM file WHERE commit_reference ={ commit_id}
ex.
SELECT file_name file FROM file WHERE commit_reference = 1

#From the files i
SELECT name, patch FROM file WHERE commit_reference = 413 AND name LIKE '%\.py'

#Improved with the committer's date
SELECT com.date, f.name, f.patch FROM commits AS c INNER JOIN users AS com ON c.commiter_reference = com.user_id INNER JOIN file AS f ON c.commit_id = f.commit_reference WHERE commit_reference = 413 AND f.name LIKE '%\.py';

SELECT c.commit_id FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference WHERE r.repo_name LIKE 'luigi' AND r.repo_owner LIKE 'spotify'

# Get all the version of a given file
SELECT f.file FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference WHERE f.name LIKE 'luigi/hdfs.py' AND r.repo_name LIKE 'luigi' AND r.repo_owner LIKE 'spotify';

# Get all the files that are in the database
SELECT com.date, f.name, f.file FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference INNER JOIN users AS com ON c.commiter_reference = com.user_id WHERE r.repo_name LIKE 'Android-Universal-Image-Loader' AND r.repo_owner LIKE 'nostra13' AND f.name LIKE '%\.java' ORDER BY com.date;

SELECT DISTINCT 1 FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference WHERE r.repo_name LIKE 'luigi' AND r.repo_owner LIKE 'spotify' AND f.name LIKE '%\.py';

/* Same as the one right below */
SELECT DISTINCT c.commit_id, c.body FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference INNER JOIN users AS com ON c.commiter_reference = com.user_id WHERE r.repo_name LIKE 'Android-Universal-Image-Loader' AND r.repo_owner LIKE 'nostra13' AND c.body REGEXP '.*fix.*' ORDER BY com.date;

/* Can search for just .*bug.* but will also get 'debug' which could be desired or not */
SELECT DISTINCT c.commit_id, c.body FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference INNER JOIN users AS com ON c.commiter_reference = com.user_id WHERE r.repo_name LIKE 'Android-Universal-Image-Loader' AND r.repo_owner LIKE 'nostra13' AND c.body REGEXP '.*bug.*' ORDER BY com.date;

/* Got nothing */
SELECT DISTINCT c.commit_id, c.body FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference INNER JOIN users AS com ON c.commiter_reference = com.user_id WHERE r.repo_name LIKE 'Android-Universal-Image-Loader' AND r.repo_owner LIKE 'nostra13'  AND c.body REGEXP '.*feature.*' ORDER BY com.date;

SELECT DISTINCT c.commit_id, c.body FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference INNER JOIN users AS com ON c.commiter_reference = com.user_id WHERE r.repo_name LIKE 'Android-Universal-Image-Loader' AND r.repo_owner LIKE 'nostra13'  AND c.body REGEXP '.*new.*' ORDER BY com.date;

SELECT DISTINCT c.commit_id, c.body FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference INNER JOIN users AS com ON c.commiter_reference = com.user_id WHERE r.repo_name LIKE 'Android-Universal-Image-Loader' AND r.repo_owner LIKE 'nostra13'  AND c.body REGEXP '.*add.*' ORDER BY com.date;

SELECT DISTINCT c.commit_id, c.body FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference INNER JOIN users AS com ON c.commiter_reference = com.user_id WHERE r.repo_name LIKE 'Android-Universal-Image-Loader' AND r.repo_owner LIKE 'nostra13'  AND c.body REGEXP '.*changed.*' ORDER BY com.date;

SELECT DISTINCT c.commit_id, c.body FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference INNER JOIN users AS com ON c.commiter_reference = com.user_id WHERE r.repo_name LIKE 'Android-Universal-Image-Loader' AND r.repo_owner LIKE 'nostra13'  AND c.body REGEXP '.*problem.*' ORDER BY com.date;

SELECT DISTINCT c.commit_id, c.body FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference INNER JOIN users AS com ON c.commiter_reference = com.user_id WHERE r.repo_name LIKE 'Android-Universal-Image-Loader' AND r.repo_owner LIKE 'nostra13'  AND c.body REGEXP '.*issue.*' ORDER BY com.date;


/* Get all the file names with full path on repo.
SELECT DISTINCT f.name FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference INNER JOIN users AS com ON c.commiter_reference = com.user_id WHERE r.repo_name LIKE 'luigi' AND r.repo_owner LIKE 'spotify' ORDER BY com.date;
#r.repo_name LIKE 'luigi' AND r.repo_owner LIKE 'spotify'*/

SELECT commit_date, total_comments, total_code FROM commits ORDER BY commit_date;

SELECT DATE(commit_date), SUM(total_comments), SUM(total_code) FROM commits GROUP BY DATE(commit_date) ORDER BY commit_date;

SELECT DATE_FORMAT(c.commit_date, '%Y-%m'), SUM(c.total_comment_addition), SUM(c.total_comment_deletion), SUM(c.total_code_addition), SUM(c.total_code_deletion) FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference WHERE r.repo_name LIKE 'Android-Universal-Image-Loader' AND r.repo_owner LIKE 'nostra13' GROUP BY DATE_FORMAT(commit_date, '%Y-%m') ORDER BY c.commit_date

/* Query to remove 'empty' commits */
SELECT c.commit_date, c.total_comment_addition, c.total_comment_deletion, c.total_code_addition, c.total_code_deletion FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference WHERE r.repo_name LIKE 'Android-Universal-Image-Loader' AND r.repo_owner LIKE 'nostra13' AND c.total_comment_addition + c.total_comment_deletion + c.total_code_addition + c.total_code_deletion != 0 ORDER BY c.commit_date

SELECT c.commit_date, c.total_comment_addition, c.total_comment_deletion, c.total_code_addition, c.total_code_deletion FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference WHERE r.repo_name LIKE 'acra' AND r.repo_owner LIKE 'ACRA' AND (c.total_comment_addition + c.total_comment_deletion + c.total_code_addition + c.total_code_deletion) != 0 ORDER BY c.commit_date

SELECT DISTINCT name FROM file WHERE name Like 'UniversalImageLoader%';
