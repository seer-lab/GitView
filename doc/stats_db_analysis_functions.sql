sql_functions


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


## Get the number of commits the method was in where it had a change made to it
drop function if exists existing_commit_count;
# For performance this might be better as an inner join rather than performing this query per row.
DELIMITER $$
CREATE FUNCTION existing_commit_count(repo_owner VARCHAR(64), repo_name
        VARCHAR(64), commit_date DATETIME, path TEXT, name TEXT,
        signature TEXT)
    RETURNS INTEGER UNSIGNED
    COMMENT 'Return the number of commits the method has previous been involved in (and been changed in)'

BEGIN
    DECLARE commit_count INTEGER UNSIGNED;

    SELECT distinct
        count(c.commit_id) INTO commit_count
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
        c.commit_date < commit_date AND
        f.path = path AND
        f.name = name AND
        mi.signature = signature;

    return commit_count;
END;
$$

## Get the number of commits before a certain date.
drop procedure if exists current_commit_count;

DELIMITER $$
CREATE PROCEDURE current_commit_count(repo_owner VARCHAR(64), repo_name
        VARCHAR(64))
    COMMENT 'Return the current commit count'

BEGIN
    SELECT distinct
        c2.commit_id as commit_id,
        count(c2.commit_id) as 'previous_commit_count'
    FROM
        repositories AS r INNER JOIN
        commits AS c ON r.repo_id = c.repo_reference INNER JOIN
        commits AS c2 ON c.repo_reference = c2.repo_reference
    WHERE
        r.repo_name LIKE repo_name AND
        r.repo_owner LIKE repo_owner AND
        c.commit_date < c2.commit_date
    GROUP BY
        c2.commit_id;
END;
$$


DELIMITER ;


# This query ignores the first commit since it doesn't have any history
SELECT
    c2.commit_id as commit_id,
    count(c2.commit_id) as 'previous_commit_count'
FROM
    commits AS c INNER JOIN
    commits AS c2 ON c.repo_reference = c2.repo_reference
WHERE
    c.commit_date < c2.commit_date
GROUP BY
    c2.commit_id

# Based on query above.
CREATE VIEW
    current_commit_count
AS
    SELECT
        c2.commit_id as commit_id,
        count(c2.commit_id) as 'previous_commit_count'
    FROM
        commits AS c INNER JOIN
        commits AS c2 ON c.repo_reference = c2.repo_reference
    WHERE
        c.commit_date < c2.commit_date
    GROUP BY
        c2.commit_id;


drop view if exists previous_change_type;

create view
    previous_change_type
AS
    SELECT
        c.repo_reference,
        c.commit_date,
        f.path,
        f.name,
        mi.signature,
        mi.method_info_id,
        mi.change_type
    FROM
        commits AS c INNER JOIN
        file AS f ON c.commit_id = f.commit_reference INNER JOIN
        method as m ON f.file_id = m.file_reference INNER JOIN
        method_info as mi ON m.method_id = mi.method_id
    order by
        c.commit_date;

c.commit_date < commit_date AND
c.repo_reference = repo_reference AND
f.path = path AND
f.name = name AND
mi.signature = signature

case when Item_Type = "change_4" then Item_Amount end as "change_4",


SELECT
    c.repo_reference,
    c.commit_date,
    f.path,
    f.name,
    mi.signature,
    mi.method_info_id,
    (SELECT GROUP_CONCAT(val.change_type)
     FROM (SELECT cc.repo_reference, ff.path, ff.name,
        mmi.signature, mmi.change_type FROM      
    commits AS cc INNER JOIN
    file AS ff ON cc.commit_id = ff.commit_reference INNER JOIN
    method as mm ON ff.file_id = mm.file_reference INNER JOIN
    method_info as mmi ON mm.method_id = mmi.method_id
    WHERE c.repo_reference = cc.repo_reference
    AND f.path = ff.path
    AND f.name = ff.name
    AND mi.signature = mmi.signature
    AND cc.commit_date < c.commit_date
    ORDER BY cc.commit_date DESC
    LIMIT 5) AS val
    group by cc.repo_reference, ff.path, ff.name, mmi.signature)

FROM
    commits AS c INNER JOIN
    file AS f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id
order by
    c.commit_date;


# Move over to postgresql cause can't make queries
# Use http://pgloader.io/

CREATE OR REPLACE FUNCTION has_next_commit(repo_reference integer,
        commit_date timestamp with time zone, path TEXT, name TEXT,
        signature TEXT)
    RETURNS INTEGER
    AS $$
    SELECT
        count(mi.signature)::integer
    FROM
        commits AS c INNER JOIN
        file AS f ON c.commit_id = f.commit_reference INNER JOIN
        method as m ON f.file_id = m.file_reference INNER JOIN
        method_info as mi ON m.method_id = mi.method_id
    WHERE
        c.repo_reference = repo_reference AND
        c.commit_date > commit_date AND
        f.path LIKE path AND
        f.name LIKE name AND
        mi.signature LIKE signature
    LIMIT 6;
$$ LANGUAGE SQL;

mi.change_type > 0 AND

c.commit_date < commit_date + INTERVAL '1 month'

SELECT
    count(mi.signature)::integer
FROM
    repositories AS r INNER JOIN
    commits AS c ON r.repo_id = c.repo_reference INNER JOIN
    file AS f ON c.commit_id = f.commit_reference INNER JOIN
    method as m ON f.file_id = m.file_reference INNER JOIN
    method_info as mi ON m.method_id = mi.method_id
where
    mi.change_type > 0
group by
    mi.signature


CREATE OR REPLACE FUNCTION has_next_commit(bigint,
        timestamp with time zone, TEXT, TEXT, TEXT)
    RETURNS INTEGER
    AS $$
    SELECT
        (count(mmi.signature) > 0)::integer
    FROM
        commits AS cc INNER JOIN
        file AS ff ON cc.commit_id = ff.commit_reference INNER JOIN
        method as mm ON ff.file_id = mm.file_reference INNER JOIN
        method_info as mmi ON mm.method_id = mmi.method_id
    WHERE
        cc.repo_reference = $1 AND
        cc.commit_date > $2 AND
        cc.commit_date < $2 + INTERVAL '1 month' AND
        ff.path LIKE $3 AND
        ff.name LIKE $4 AND
        mmi.signature LIKE $5
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION exists_in_commits(bigint,
        timestamp with time zone, TEXT, TEXT, TEXT)
    RETURNS bigint
    AS $$
    SELECT distinct
        count(c.commit_id)
    FROM
        repositories AS r INNER JOIN
        commits AS c ON r.repo_id = c.repo_reference INNER JOIN
        file AS f ON c.commit_id = f.commit_reference INNER JOIN
        method as m ON f.file_id = m.file_reference INNER JOIN
        method_info as mi ON m.method_id = mi.method_id
    WHERE
        c.repo_reference = $1 AND
        mi.change_type > 0 AND
        c.commit_date < $2 AND
        f.path = $3 AND
        f.name = $4 AND
        mi.signature = $5;
$$ LANGUAGE SQL;


CREATE VIEW
    current_commit_count
AS
    SELECT
        c2.commit_id as commit_id,
        count(c2.commit_id) as previous_commit_count
    FROM
        commits AS c INNER JOIN
        commits AS c2 ON c.repo_reference = c2.repo_reference
    WHERE
        c.commit_date < c2.commit_date
    GROUP BY
        c2.commit_id;

CREATE OR REPLACE FUNCTION previous_change_type(bigint,
        timestamp with time zone, text, text, text)
    RETURNS TABLE(change_type bigint[], diff_indate double precision[])
    AS $$
    SELECT
        array_agg(change_type),
        array_agg(diffs)
    FROM
        (SELECT
            mmi.change_type AS change_type,
            EXTRACT(EPOCH FROM (lead(commit_date, 1, $2) OVER (ORDER BY commit_date) - commit_date)) AS diffs
        FROM
            commits AS cc INNER JOIN
            file AS ff ON cc.commit_id = ff.commit_reference INNER JOIN
            method as mm ON ff.file_id = mm.file_reference INNER JOIN
            method_info as mmi ON mm.method_id = mmi.method_id
        WHERE
            cc.repo_reference = $1 AND
            ff.path = $3 AND
            ff.name = $4 AND
            mmi.signature = $5 AND
            cc.commit_date < $2
        ORDER BY
            cc.commit_date DESC
        LIMIT 5) tt;
$$ LANGUAGE SQL;


(lead(cc.commit_date) - cc.commit_date)

OVER (PARITION BY mmi.signature) as diffs