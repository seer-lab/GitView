SELECT c1.* FROM parent_commits AS p1 INNER JOIN commits AS c1 ON p1.parent_id = c1.commit_id, commits AS c2 WHERE c2.commit_id=2;

SELECT r.repo_name, com.name, com.date, aut.name, c1.body, c1.sha_hash
FROM repositories AS r INNER JOIN commits AS c1 ON r.repo_id = c1.repo_reference INNER JOIN users AS com ON c1.commiter_reference = com.user_id INNER JOIN
	users AS aut ON c1.author_reference = aut.user_id;