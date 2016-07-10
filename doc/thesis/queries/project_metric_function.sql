CREATE OR REPLACE FUNCTION project_metrics(TEXT, TEXT)
    RETURNS TABLE (
        owner text,
        repo text,
        avg_c_p_y numeric,
    max_c_p_y numeric,
    min_c_p_y numeric,
    avg_mpc numeric,
    avg_mpcpy numeric,
    max_mpcpy numeric,
    min_mpcpy numeric,
    avg_c_p_m numeric,
    max_c_p_m numeric,
    min_c_p_m numeric,
      avg_c_p_c numeric,
    max_c_p_c numeric,
    min_c_p_c numeric,
    avg_a_p_c numeric,
    max_a_p_c numeric,
    min_a_p_c numeric,
      mcc numeric,
      mc numeric,
      start_date date,
      end_date date,
      time_length numeric,
      start_year numeric,
      end_year numeric,
      cc numeric,
      project_length text,
      commit_rate text,
      project_size text
        )
    AS $$
DECLARE
    
BEGIN

with year_counts as
(
    select
        count(c.commit_id) as commit_count
    from
        repositories as r INNER JOIN
        commits AS c ON r.repo_id = c.repo_reference
    where
        r.repo_owner = $1 AND
        r.repo_name = $2
    group by
        EXTRACT(YEAR FROM c.commit_date)
)
select
    SUM(yc.commit_count) / count(yc.commit_count)::numeric as avg_commits_per_year, 
    MAX(yc.commit_count) as max_commits_per_year,
    MIN(yc.commit_count) as min_commits_per_year
into
    avg_c_p_y, max_c_p_y, min_c_p_y
from 
    year_counts as yc;

with method_change_list as
(
    select
        c.commit_id,
        c.commit_date,
        mmi.change_type,
        mmi.signature
    from
        repositories as r INNER JOIN
        commits AS c ON r.repo_id = c.repo_reference INNER JOIN
        file AS ff ON c.commit_id = ff.commit_reference INNER JOIN
        method as mm ON ff.file_id = mm.file_reference INNER JOIN
        method_info as mmi ON mm.method_id = mmi.method_id
    where
        r.repo_owner = $1 AND
        r.repo_name = $2
    group by
        c.commit_id,
        mmi.signature,
        mmi.change_type
    having
        mmi.change_type > 0
), method_change_summary as
(
    select
        mcl.commit_id,
        count(mcl.signature) as method_changes_count
    from
        method_change_list as mcl
    group by
        mcl.commit_id
)
select
    SUM(mcs.method_changes_count) / count(mcs.commit_id)::numeric as avg_method_per_commits
into
    avg_mpc
from 
    method_change_summary as mcs;

with method_change_list as
(
    select
        c.commit_id,
        c.commit_date,
        mmi.change_type,
        mmi.signature
    from
        repositories as r INNER JOIN
        commits AS c ON r.repo_id = c.repo_reference INNER JOIN
        file AS ff ON c.commit_id = ff.commit_reference INNER JOIN
        method as mm ON ff.file_id = mm.file_reference INNER JOIN
        method_info as mmi ON mm.method_id = mmi.method_id
    where
        r.repo_owner = $1 AND
        r.repo_name = $2
    group by
        c.commit_id,
        mmi.signature,
        mmi.change_type
    having
        mmi.change_type > 0
), method_change_summary as
(
    select
        mcl.commit_id,
        count(mcl.signature) as method_changes_count
    from
        method_change_list as mcl
    group by
        mcl.commit_id
        
), yearly_summary as
(
    select
        EXTRACT(YEAR FROM c.commit_date) as year,
        sum(mcs.method_changes_count) as method_count
    from
        method_change_summary as mcs inner join
        commits as c on c.commit_id = mcs.commit_id
    group by
        year
)
select
    SUM(ys.method_count) / count(ys.year)::numeric as avg_method_per_commits_per_year,
    MAX(ys.method_count) as max_methods_per_commit_per_year,
    MIN(ys.method_count) as min_methods_per_commit_per_year
into
    avg_mpcpy,
    max_mpcpy,
    min_mpcpy
from 
    yearly_summary as ys;

with method_change_list as
(
    select
        c.commit_id,
        mmi.change_type,
        mmi.signature
    from
        repositories as r INNER JOIN
        commits AS c ON r.repo_id = c.repo_reference INNER JOIN
        file AS ff ON c.commit_id = ff.commit_reference INNER JOIN
        method as mm ON ff.file_id = mm.file_reference INNER JOIN
        method_info as mmi ON mm.method_id = mmi.method_id
    where
        r.repo_owner = $1 AND
        r.repo_name = $2
    group by
        c.commit_id,
        mmi.signature,
        mmi.change_type
    having
        mmi.change_type > 0
), method_change_summary as
(
    select
        count(mcl.signature) as method_changes_count
    from
        method_change_list as mcl
    group by
        mcl.signature
)
select
    AVG(mcs.method_changes_count) as avg_changes_per_method,
    MAX(mcs.method_changes_count) as max_changes_per_method,
    MIN(mcs.method_changes_count) as min_changes_per_method
into
    avg_c_p_m,
    max_c_p_m,
    min_c_p_m
from 
    method_change_summary as mcs;

with dev_counts as
(
    select
        com.name as committer_name,
        aut.name as author_name
    from
        repositories as r INNER JOIN
        commits AS c ON r.repo_id = c.repo_reference INNER JOIN
        users as com ON c.committer_id = com.user_id INNER JOIN
        users as aut ON c.author_id = aut.user_id
    where
        r.repo_owner = $1 AND
        r.repo_name = $2
), committer_counts as
(
    select
        count(dc.committer_name) as committer_count
    from
        dev_counts as dc
    group by
        dc.committer_name
), author_counts as
(
    select
        count(dc.author_name) as author_count
    from
        dev_counts as dc
    group by
        dc.author_name
)
select
    AVG(cc.committer_count) as avg_commits_per_committer, 
    MAX(cc.committer_count) as max_commits_per_committer,
    MIN(cc.committer_count) as min_commits_per_committer,

    AVG(ac.author_count) as avg_commits_per_author, 
    MAX(ac.author_count) as max_commits_per_author,
    MIN(ac.author_count) as min_commits_per_author

into
    avg_c_p_c,
    max_c_p_c,
    min_c_p_c,

    avg_a_p_c,
    max_a_p_c,
    min_a_p_c
from 
    committer_counts as cc, author_counts as ac;

with method_change_list as
(
    select
        c.commit_id,
        c.commit_date,
        mmi.change_type,
        mmi.signature
    from
        repositories as r INNER JOIN
        commits AS c ON r.repo_id = c.repo_reference INNER JOIN
        file AS ff ON c.commit_id = ff.commit_reference INNER JOIN
        method as mm ON ff.file_id = mm.file_reference INNER JOIN
        method_info as mmi ON mm.method_id = mmi.method_id
    where
        r.repo_owner = $1 AND
        r.repo_name = $2
    group by
        c.commit_id,
        mmi.signature,
        mmi.change_type
    having
        mmi.change_type > 0
)
select
    count(mcl.signature) as method_changes_count
into
    mcc
from
    method_change_list as mcl;

with method_change_list as
(
    select
        c.commit_id,
        f.path,
        f.name,
        mmi.change_type,
        mmi.signature
    from
        repositories as r INNER JOIN
        commits AS c ON r.repo_id = c.repo_reference INNER JOIN
        file AS f ON c.commit_id = f.commit_reference INNER JOIN
        method as mm ON f.file_id = mm.file_reference INNER JOIN
        method_info as mmi ON mm.method_id = mmi.method_id
    where
        r.repo_owner = $1 AND
        r.repo_name = $2
    group by
        c.commit_id,
        f.path,
        f.name,
        mmi.signature,
        mmi.change_type
    having
        mmi.change_type > 0
), method_counts as
(
    select
        count(mcl.signature) as methods_count
    from
        method_change_list as mcl
    group by
        mcl.path,
        mcl.name,
        mcl.signature
)
select
    count(mc.methods_count) as method_count
into
    mc
from
    method_counts as mc;

with project_duration as
(
    select
        min(c.commit_date) as first_commit,
        max(c.commit_date) as last_commit
    from
        repositories as r INNER JOIN
        commits AS c ON r.repo_id = c.repo_reference
    where
        r.repo_owner = $1 AND
        r.repo_name = $2
)
select
    first_commit::date,
    last_commit::date
into
    start_date, end_date
from 
    project_duration as yc;

with year_counts as
(
    select
        EXTRACT(YEAR FROM c.commit_date) as year,
        count(c.commit_id) as commit_count
    from
        repositories as r INNER JOIN
        commits AS c ON r.repo_id = c.repo_reference
    where
        r.repo_owner = $1 AND
        r.repo_name = $2
    group by
        EXTRACT(YEAR FROM c.commit_date)
)
select
    max(yc.year) - (min(yc.year) - 1) as duration,
    min(yc.year),
    max(yc.year)
into
    time_length, start_year, end_year
from 
    year_counts as yc;

select
    count(c.commit_id) as commit_count
into
    cc
from
    repositories as r INNER JOIN
    commits AS c ON r.repo_id = c.repo_reference
where
    r.repo_owner = $1 AND
    r.repo_name = $2;

RETURN QUERY select
            $1,
            $2,
            avg_c_p_y as "avg commit per year",
            max_c_p_y,
            min_c_p_y,
              avg_mpc,
            avg_mpcpy,
            max_mpcpy,
            min_mpcpy,
            avg_c_p_m,
            max_c_p_m,
            min_c_p_m,
              avg_c_p_c,
            max_c_p_c,
            min_c_p_c,
            avg_a_p_c,
            max_a_p_c,
            min_a_p_c,
              mcc,
              mc,
              start_date,
            end_date,
              time_length,
              start_year,
              end_year,
              cc,
              CASE WHEN time_length < 1 THEN 'short'
                   WHEN time_length >= 1 AND time_length < 3 THEN 'medium'
                   ELSE 'long'
              END,
              CASE WHEN avg_c_p_y < 100 THEN 'low'
                   WHEN avg_c_p_y >= 100 AND avg_c_p_y < 300 THEN 'medium'
                   WHEN avg_c_p_y >= 300 AND avg_c_p_y < 600 THEN 'high'
                   ELSE 'very high'
              END,
              CASE WHEN mc < 2000 THEN 'small'
                   WHEN mc >= 2000 AND mc < 10000 THEN 'medium'
                   ELSE 'large'
              END
              ;
END;
$$ language plpgsql;