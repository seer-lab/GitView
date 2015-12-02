

# One of the problems with the way the data is laid out currently
    # The database was organized such to store the data and less so to organize the data based on lower level connections
#        - For example;
#            - Method's table should really be method summary table.
#            - There should really be a layer between method info and method (to basically link the methods with the same signature).
#            - Essentially there is no interlinkage between commits beyond (the order is only preserved through data (and usually commit_id ordering))
#                - Files could be linked based on being the same file of different versions
#repositories (repo_id = repo_reference)
#    -> commits (commit_id = commit_reference)
#        -> file (file_id = file_reference)
#            *code/comment counts
#            -> method
#                *new/deleted/modified counts    
#                    - (for a given file)
#                -> method_info (method_id = method_id)
#                    * signature
#                    * change type
#                    - The individual methods changed per file.
#            -> method_statement (file_id = file_reference)
#                *code/comment new/deleted/modified(added/deleted)
#    -> tags (repo_id = repo_reference)


# We could definitely, map string names to numerical values.
# "CrashReport/src/org/acra/" => 1, "CrashReport/sample/org/acra/sampleapp/" => 2

# Consider whether I need path and name or just the file at the time is fine.
select
    c.commit_id,
    f.file_id,
    f.path,
    f.name,
    mi.signature,   
    mi.change_type,
    aut.name as "Author",
    com.name as "Committer"
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    user as aut ON c.author_id = aut.user_id INNER JOIN
    user as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id
LIMIT 10;


# Rather than using the mi.method_info_id it would better to use
# mi.signature => <int> since there is no table that stores unique method signatures

# This query collects the change frequency of each method
# This may need to be normalized through change_frequency(i)/num_commits
SELECT
    c.commit_id,
    f.path,
    f.name,
    COUNT(mi.change_type) as 'change_frequency',
    mi.signature
FROM
    repositories AS r INNER JOIN
    commits AS c ON r.repo_id = c.repo_reference INNER JOIN
    file AS f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id
WHERE
    r.repo_name LIKE 'acra' AND
    r.repo_owner LIKE 'ACRA' AND
    mi.change_type > 0
GROUP BY
    f.path,
    f.name,
    mi.signature
ORDER BY
    f.path,
    f.name,
    mi.signature
LIMIT 100;


SELECT
    c.commit_id,
    f.path,
    f.name,
    mi.change_type,
    mi.signature
FROM
    repositories AS r INNER JOIN
    commits AS c ON r.repo_id = c.repo_reference INNER JOIN
    file AS f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id
WHERE
    r.repo_name LIKE 'acra' AND
    r.repo_owner LIKE 'ACRA' AND
    mi.change_type > 0
ORDER BY
    f.path,
    f.name,
    mi.signature
LIMIT 60, 22;

# Get the unique details of each method
select distinct
    c.commit_id,
    f.file_id,
    f.path,
    f.name,
    mi.signature,   
    mi.change_type,
    aut.name as "Author",
    com.name as "Committer",
    ch.change_frequency
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    user as aut ON c.author_id = aut.user_id INNER JOIN
    user as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id INNER JOIN
    (
        SELECT distinct
            f_2.path,
            f_2.name,
            mi_2.signature,
            COUNT(mi_2.change_type) as 'change_frequency'
        FROM
            repositories AS r_2 INNER JOIN
            commits AS c_2 ON r_2.repo_id = c_2.repo_reference INNER JOIN
            file AS f_2 ON c_2.commit_id = f_2.commit_reference INNER JOIN
            method as m_2 ON f_2.file_id = m_2.file_reference INNER JOIN
            method_info as mi_2 ON m_2.method_id = mi_2.method_id
        WHERE
            r_2.repo_name LIKE 'acra' AND
            r_2.repo_owner LIKE 'ACRA' AND
            mi_2.change_type > 0
        GROUP BY
            f_2.path,
            f_2.name,
            mi_2.signature
        ORDER BY
            f_2.path,
            f_2.name,
            mi_2.signature
    ) as ch ON ch.path = f.path 
        AND ch.name = f.name
        AND ch.signature = mi.signature
LIMIT 30;


SELECT distinct
    c.commit_id,
    f.path,
    f.name,
    mi.change_type,
    mi.signature
FROM
    repositories AS r INNER JOIN
    commits AS c ON r.repo_id = c.repo_reference INNER JOIN
    file AS f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id
WHERE
    r.repo_name LIKE 'acra' AND
    r.repo_owner LIKE 'ACRA' AND
    mi.change_type > 0 AND
    c.commit_date > 'date' AND
    f.path = 'path' AND
    f.name = 'name' AND
    mi.signature = 'signature'
LIMIT 6

# Make so that it will only involve methods that have changed in the commit (not unchanged methods)
mi.change_type > 0

# Ensures that we are getting a commit after the commit in question
c.commit_date > 'date'

# These ensure we are matching the same method signature within the same class *(excluding anon method defs which break this).
f.path = 'path' AND
f.name = 'name' AND
mi.signature = 'signature'



drop function if exists has_next_commit;

DELIMITER $$
CREATE FUNCTION has_next_commit(repo_owner VARCHAR(64), repo_name
        VARCHAR(64), commit_date DATETIME, path TEXT, name TEXT,
        signature TEXT)
    RETURNS INTEGER UNSIGNED
    COMMENT 'Return is 1 if a commit exists otherwise 0'

BEGIN
    DECLARE has_next INTEGER UNSIGNED;

    SELECT distinct
        count(mi.signature) INTO has_next
    FROM
        repositories AS r INNER JOIN
        commits AS c ON r.repo_id = c.repo_reference INNER JOIN
        file AS f ON c.commit_id = f.commit_reference INNER JOIN
        method as m ON f.file_id = m.file_reference INNER JOIN
        method_info as mi ON m.method_id = mi.method_id
    WHERE
        r.repo_name LIKE repo_name AND
        r.repo_owner LIKE repo_owner AND
        mi.change_type > 0 AND
        c.commit_date > commit_date AND
        f.path = path AND
        f.name = name AND
        mi.signature = signature
    LIMIT 6;

    if has_next > 0 then
        return 1;
    else
        return 0;
    end if;
END;
$$

DELIMITER ;

select distinct
    c.commit_id,
    f.path,
    f.name,
    mi.signature,   
    mi.change_type,
    aut.name as "Author",
    com.name as "Committer",
    has_next_commit('ACRA', 'acra', c.commit_date, f.path, f.name, mi.signature) as "has_next?"
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    user as aut ON c.author_id = aut.user_id INNER JOIN
    user as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'acra'
limit 10;


** Consider changing the outer where to prevent unchanged methods from showing up (add 'AND mi.change_type > 0')
    - This does reduce the dataset from around 16000 to 3600. 
select distinct
    c.commit_id,
    f.path,
    f.name,
    mi.method_info_id,
    mi.signature,   
    mi.change_type,
    aut.name as "Author",
    com.name as "Committer",
    ch.change_frequency,
    has_next_commit('ACRA', 'acra', c.commit_date, f.path, f.name, mi.signature) as "has_next?"
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    user as aut ON c.author_id = aut.user_id INNER JOIN
    user as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id INNER JOIN
     as ch ON ch.path = f.path 
        AND ch.name = f.name
        AND ch.signature = mi.signature
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'acra'
order by
    rand()
limit 1;

 AND
    mi.change_type > 0
LIMIT 30;


- Get the count() of the number of elements in the list
- Get the max and min of the mi.id column

select distinct
    c.commit_id,
    f.path,
    f.name,
    mi.method_info_id,
    mi.signature,
    mi.change_type
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    user as aut ON c.author_id = aut.user_id INNER JOIN
    user as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id INNER JOIN
    (
        SELECT distinct
            f_2.path,
            f_2.name,
            mi_2.signature,
            COUNT(mi_2.change_type) as 'change_frequency'
        FROM
            repositories AS r_2 INNER JOIN
            commits AS c_2 ON r_2.repo_id = c_2.repo_reference INNER JOIN
            file AS f_2 ON c_2.commit_id = f_2.commit_reference INNER JOIN
            method as m_2 ON f_2.file_id = m_2.file_reference INNER JOIN
            method_info as mi_2 ON m_2.method_id = mi_2.method_id
        WHERE
            r_2.repo_name LIKE 'acra' AND
            r_2.repo_owner LIKE 'ACRA' AND
            mi_2.change_type > 0
        GROUP BY
            f_2.path,
            f_2.name,
            mi_2.signature
    ) as ch ON ch.path = f.path 
        AND ch.name = f.name
        AND ch.signature = mi.signature
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'acra'
order by
    RAND()
LIMIT 1000;

 AND
    mi.change_type > 0


# Removed author, path
select distinct
    c.commit_id,
    f.name,
    mi.method_info_id,
    mi.signature,   
    mi.change_type,
    com.name as "Committer",
    ch.change_frequency,
    has_next_commit('ACRA', 'acra', c.commit_date, f.path, f.name, mi.signature) as "has_next?"
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    user as aut ON c.author_id = aut.user_id INNER JOIN
    user as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id INNER JOIN
    (
        SELECT distinct
            f_2.path,
            f_2.name,
            mi_2.signature,
            COUNT(mi_2.change_type) as 'change_frequency'
        FROM
            repositories AS r_2 INNER JOIN
            commits AS c_2 ON r_2.repo_id = c_2.repo_reference INNER JOIN
            file AS f_2 ON c_2.commit_id = f_2.commit_reference INNER JOIN
            method as m_2 ON f_2.file_id = m_2.file_reference INNER JOIN
            method_info as mi_2 ON m_2.method_id = mi_2.method_id
        WHERE
            r_2.repo_name LIKE 'acra' AND
            r_2.repo_owner LIKE 'ACRA' AND
            mi_2.change_type > 0
        GROUP BY
            f_2.path,
            f_2.name,
            mi_2.signature
    ) as ch ON ch.path = f.path 
        AND ch.name = f.name
        AND ch.signature = mi.signature
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'acra'
order by
    rand()
limit 1;

 AND
    mi.change_type > 0
LIMIT 30;



select distinct
    c.commit_id,
    f.name,
    mi.method_info_id,
    mi.signature,   
    mi.change_type,
    com.name as "Committer",
    existing_commit_count('ACRA', 'acra', c.commit_date, f.path, f.name, mi.signature) as 'existing_commit_count',
    pcc.previous_commit_count,
    has_next_commit('ACRA', 'acra', c.commit_date, f.path, f.name, mi.signature) as "has_next?"
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    user as aut ON c.author_id = aut.user_id INNER JOIN
    user as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id INNER JOIN
    current_commit_count as pcc ON pcc.commit_id = c.commit_id
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'acra'
LIMIT 100;


select
    c.commit_id,
    f.path,
    f.name,
    mi.method_info_id,
    mi.signature,   
    mi.change_type,
    com.name as "Committer",
    existing_commit_count('ACRA', 'acra', c.commit_date, f.path, f.name, mi.signature) / pcc.previous_commit_count as change_frequency,
    has_next_commit('ACRA', 'acra', c.commit_date, f.path, f.name, mi.signature) as "has_next?"
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    user as aut ON c.author_id = aut.user_id INNER JOIN
    user as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id INNER JOIN
    current_commit_count as pcc ON pcc.commit_id = c.commit_id
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'acra' AND
    f.path LIKE 'acra/%'
order by 
    RAND()
LIMIT 20;

as 'existing_commit_count'

select
    c.commit_id,
    c.commit_date,
    pct.commit_date as prev_date,
    f.path,
    f.name,
    mi.signature,
    mi.method_info_id,
    mi.change_type,
    pct.change_type as prev_change_type
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    user as aut ON c.author_id = aut.user_id INNER JOIN
    user as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id INNER JOIN
    previous_change_type as pct ON 
        pct.repo_reference = c.repo_reference AND
        pct.path = f.path AND
        pct.name = f.name AND
        pct.commit_date < c.commit_date
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'acra' AND
    f.path LIKE 'acra/%'
group by
    mi.method_info_id

# Group by the mi.method_info_id to allow for us to pivot the previous change types.

    c.commit_date < commit_date AND
c.repo_reference = repo_reference AND
f.path = path AND
f.name = name AND
mi.signature = signature

select
    mi.change_type
from
    method_info as mi


# PostgreSQL queries

select
    c.commit_id,
    f.path,
    f.name,
    mi.method_info_id,
    mi.signature,   
    mi.change_type,
    com.name as "Committer"
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    users as aut ON c.author_id = aut.user_id INNER JOIN
    users as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'ACRA' AND
    f.path LIKE 'acra/%'


# Rebuild has_next?
has_next_commit('ACRA', 'acra', c.commit_date, f.path, f.name, mi.signature) as "has_next?"

select
    c.commit_id,
    f.path,
    f.name,
    mi.method_info_id,
    mi.signature,   
    mi.change_type,
    com.name as "Committer",
    (SELECT
        (count(mmi.signature) > 0)::integer
    FROM
        commits AS cc INNER JOIN
        file AS ff ON cc.commit_id = ff.commit_reference INNER JOIN
        method as mm ON ff.file_id = mm.file_reference INNER JOIN
        method_info as mmi ON mm.method_id = mmi.method_id
    WHERE
        cc.repo_reference = c.repo_reference AND
        cc.commit_date > c.commit_date AND
        ff.path LIKE f.path AND
        ff.name LIKE f.name AND
        mmi.signature LIKE mi.signature
    LIMIT 6) as has_next
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    users as aut ON c.author_id = aut.user_id INNER JOIN
    users as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'ACRA'


# Limit the amount of commits by 6
select
    c.commit_id,
    f.path,
    f.name,
    mi.method_info_id,
    mi.signature,   
    mi.change_type,
    com.name as "Committer",
    (
    SELECT
        count(next_six.signature)
    FROM 
        (SELECT
            ff.path,
            ff.name,
            mmi.signature
        FROM
            commits AS cc INNER JOIN
            file AS ff ON cc.commit_id = ff.commit_reference INNER JOIN
            method as mm ON ff.file_id = mm.file_reference INNER JOIN
            method_info as mmi ON mm.method_id = mmi.method_id
        WHERE
            cc.repo_reference = c.repo_reference AND
            cc.commit_date > c.commit_date
        LIMIT 6) as next_six
    WHERE
        next_six.path LIKE f.path AND
        next_six.name LIKE f.name AND
        next_six.signature LIKE mi.signature) as has_next
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    users as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'ACRA'

# Uses an inner query to get the has next (working)
select
    c.commit_id,
    f.path,
    f.name,
    mi.method_info_id,
    mi.signature,   
    mi.change_type,
    com.name as "Committer",
    (
    SELECT
        (count(mmi.signature) > 0)::integer
    FROM
        commits AS cc INNER JOIN
        file AS ff ON cc.commit_id = ff.commit_reference INNER JOIN
        method as mm ON ff.file_id = mm.file_reference INNER JOIN
        method_info as mmi ON mm.method_id = mmi.method_id
    WHERE
        cc.repo_reference = c.repo_reference AND
        cc.commit_date > c.commit_date AND
        cc.commit_date < c.commit_date + INTERVAL '1 month' AND
        ff.path LIKE f.path AND
        ff.name LIKE f.name AND
        mmi.signature LIKE mi.signature) as has_next
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    users as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'ACRA'


# Basically where I was before collecting change_freq parts and label categories.
select
    c.commit_id,
    f.path,
    f.name,
    mi.method_info_id,
    mi.signature,   
    mi.change_type,
    com.name as "Committer",
    exists_in_commits(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) / pcc.previous_commit_count::float as change_frequency,
    has_next_commit(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) as has_next
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    users as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id INNER JOIN
    current_commit_count as pcc ON pcc.commit_id = c.commit_id
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'ACRA'

SELECT
    c.repo_reference,
    c.commit_date,
    f.path,
    f.name,
    mi.signature,
    mi.method_info_id,
    previous_change_type(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) AS prev_types
FROM
    commits AS c INNER JOIN
    file AS f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id
GROUP BY
    c.repo_reference,
    c.commit_date,
    f.path,
    f.name,
    mi.signature,
    mi.method_info_id
order by
    c.commit_date;

select
    c.commit_id,
    f.name,
    mi.method_info_id,
    mi.signature,   
    mi.change_type,
    com.name as committer,
    exists_in_commits(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) / pcc.previous_commit_count::float as change_frequency,
    previous_change_type(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) AS prev_types,
    has_next_commit(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) as has_next
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    users as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id INNER JOIN
    current_commit_count as pcc ON pcc.commit_id = c.commit_id
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'ACRA' AND
    random() < 0.5
limit
    1000
\g '/tmp/example_data_1000_2'


select
    c.commit_id,
    f.name,
    mi.method_info_id,
    mi.signature,   
    mi.change_type,
    com.name as committer,
    exists_in_commits(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) / pcc.previous_commit_count::float as change_frequency,
    previous_change_type(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) AS prev_types,
    has_next_commit(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) as has_next
from
    repositories as r INNER JOIN 
    commits as c ON r.repo_id = c.repo_reference INNER JOIN
    users as com ON c.committer_id = com.user_id INNER JOIN
    file as f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id INNER JOIN
    current_commit_count as pcc ON pcc.commit_id = c.commit_id
where 
    r.repo_name = 'acra' AND
    r.repo_owner = 'ACRA'
order by
    random()
limit
    100
\g '/tmp/test_data_100_2'


select 
    v.commit_id,
    v.name,
    v.method_info_id,
    v.signature,   
    v.no_change,
    v.add_change,
    v.delete_change,
    v.modify_change,
    v.committer,
    v.change_frequency,
    v.previous_change_type,
    v.has_next
from
    (select
        c.commit_id,
        f.name,
        mi.method_info_id,
        mi.signature,   
        CASE mi.change_type WHEN 0 THEN 1 ELSE -1 END As no_change,
        CASE mi.change_type WHEN 1 THEN 1 ELSE -1 END as add_change,
        CASE mi.change_type WHEN 2 THEN 1 ELSE -1 END as delete_change,
        CASE mi.change_type WHEN 3 THEN 1 ELSE -1 END as modify_change,
        c.commit_date,
        com.name as committer,
        exists_in_commits(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) / pcc.previous_commit_count::float as change_frequency,
        previous_change_type(c.repo_reference, c.commit_date, f.path, f.name, mi.signature),
        has_next_commit(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) as has_next
    from
        repositories as r INNER JOIN 
        commits as c ON r.repo_id = c.repo_reference INNER JOIN
        users as com ON c.committer_id = com.user_id INNER JOIN
        file as f ON c.commit_id = f.commit_reference INNER JOIN
        method as m ON f.file_id = m.file_reference INNER JOIN
        method_info as mi ON m.method_id = mi.method_id INNER JOIN
        current_commit_count as pcc ON pcc.commit_id = c.commit_id
    where 
        r.repo_name = 'acra' AND
        r.repo_owner = 'ACRA') as v
where
    v.has_next = 1 AND
    v.commit_date > '2010-04-18 15:52:18-04' AND
    v.commit_date < '2011-07-31 02:09:57.5-04'
order by
    random()
limit 50
\g '/tmp/example_data_100_q4'


select
    v.min_date,
    v.min_date+v.quarter as first_quarter,
    v.min_date+(v.quarter*2) as second_quarter,
    v.min_date+(v.quarter*3) as third_quarter,
    v.max_date
from (
    select
        min(c.commit_date) as min_date,
        max(c.commit_date) as max_date,
        (max(c.commit_date) - min(c.commit_date))/4 as quarter
    from
        repositories as r INNER JOIN
        commits as c ON r.repo_id = c.repo_reference
    where
        r.repo_name = 'acra' AND
        r.repo_owner = 'ACRA'
    ) as v