<?php

/**
 * Get all of the repositories stored in the database
 * @param $mysqli the mysql connection.
 */
function getAllRepos($mysqli)
{
     $results = array(array('repo_name'   => "",
                            'repo_owner'  => ""
                     ));

    # Changed to order in reverse to put the better repo first.
    if ($stmt = $mysqli->prepare("SELECT repo_name, repo_owner FROM repositories ORDER BY repo_id DESC"))
    {
        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result($repo_name, $repo_owner);
        $i = 0;
        while ($stmt->fetch())
        {
            $results[$i]['repo_name'] = $repo_name;
            $results[$i]['repo_owner'] = $repo_owner;
            $i++;
        }

        /* close statement */
        $stmt->close();
    }
    return $results;
}

/**
 * Get the stats for comments and code added and deleted per commit
 * @param $mysqli the mysql connection.
 * @param $user the owner of the repository.
 * @param $repo the repository to get the statistics for.
 */
function getChurn($mysqli, $user, $repo)
{
    $results = array(   'date'              => array(),
                        'commentsAdded'     => array(),
                        'commentsDeleted'   => array(),
                        'codeAdded'         => array(),
                        'codeDeleted'       => array(),
                        'totalComments'     => array(),
                        'totalCode'         => array()
                    );
    // TODO change to use only 1 repo
    if ($stmt = $mysqli->prepare("SELECT c.commit_date, c.total_comment_addition, c.total_comment_deletion, c.total_code_addition, c.total_code_deletion FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? ORDER BY c.commit_date"))
    
{       
        /* bind parameters for markers */
        $stmt->bind_param('ss', $repo, $user);

        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result($date, $commentsAdded, $commentsDeleted, $codeAdded, $codeDeleted);

        $i = 0;
        $results['totalComments'][$i] = 0;
        $results['totalCode'][$i] = 0;
        while ($stmt->fetch())
        {
            $results['date'][$i] = $date;
            $results['commentsAdded'][$i] = $commentsAdded;
            $results['commentsDeleted'][$i] = $commentsDeleted;
            $results['codeAdded'][$i] = $codeAdded;
            $results['codeDeleted'][$i] = $codeDeleted;

            if ($i > 0)
            {
                $results['totalComments'][$i] = $results['totalComments'][$i - 1];
                $results['totalCode'][$i] = $results['totalCode'][$i - 1];
            }

            $results['totalComments'][$i] += ($results['commentsAdded'][$i] - $results['commentsDeleted'][$i]);
            $results['totalCode'][$i] += ($results['codeAdded'][$i] - $results['codeDeleted'][$i]);
            $i++;
        }

        /* close statement */
        $stmt->close();
    }
    
    return $results;

}

/**
 * Get the stats for comments and code added and deleted per day
 * @param $mysqli the mysql connection.
 * @param $user the owner of the repository.
 * @param $repo the repository to get the statistics for.
 */
function getChurnDays($mysqli, $user, $repo)
{
    $results = array(   'date'              => array(),
                        'commentsAdded'     => array(),
                        'commentsDeleted'   => array(),
                        'codeAdded'         => array(),
                        'codeDeleted'       => array(),
                        'totalComments'     => array(),
                        'totalCode'         => array()
                    );

    if ($stmt = $mysqli->prepare("SELECT DATE(c.commit_date), SUM(c.total_comment_addition), SUM(c.total_comment_deletion), SUM(c.total_code_addition), SUM(c.total_code_deletion) FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? GROUP BY DATE(commit_date) ORDER BY c.commit_date"))
    {
        /* bind parameters for markers */
        $stmt->bind_param('ss', $repo, $user);

        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result($date, $commentsAdded, $commentsDeleted, $codeAdded, $codeDeleted);

        $i = 0;
        $results['totalComments'][$i] = 0;
        $results['totalCode'][$i] = 0;
        while ($stmt->fetch())
        {
            $results['date'][$i] = $date;
            $results['commentsAdded'][$i] = $commentsAdded;
            $results['commentsDeleted'][$i] = $commentsDeleted;
            $results['codeAdded'][$i] = $codeAdded;
            $results['codeDeleted'][$i] = $codeDeleted;

            if ($i > 0)
            {
                $results['totalComments'][$i] = $results['totalComments'][$i - 1];
                $results['totalCode'][$i] = $results['totalCode'][$i - 1];
            }

            $results['totalComments'][$i] += ($results['commentsAdded'][$i] - $results['commentsDeleted'][$i]);
            $results['totalCode'][$i] += ($results['codeAdded'][$i] - $results['codeDeleted'][$i]);
            $i++;
        }

        /* close statement */
        $stmt->close();
    }
    
    return $results;

}

/**
 * Get the stats for comments and code added and deleted per month.
 * @param $mysqli the mysql connection.
 * @param $user the owner of the repository.
 * @param $repo the repository to get the statistics for.
 */
function getChurnMonths($mysqli, $user, $repo)
{
    $results = array(   'date'              => array(),
                        'commentsAdded'     => array(),
                        'commentsDeleted'   => array(),
                        'codeAdded'         => array(),
                        'codeDeleted'       => array(),
                        'totalComments'     => array(),
                        'totalCode'         => array()
                    );

    if ($stmt = $mysqli->prepare("SELECT DATE_FORMAT(c.commit_date, '%Y-%m'), SUM(c.total_comment_addition), SUM(c.total_comment_deletion), SUM(c.total_code_addition), SUM(c.total_code_deletion) FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? GROUP BY DATE_FORMAT(commit_date, '%Y-%m') ORDER BY c.commit_date"))
    {
        /* bind parameters for markers */
        $stmt->bind_param('ss', $repo, $user);

        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result($date, $commentsAdded, $commentsDeleted, $codeAdded, $codeDeleted);

        $i = 0;
        $results['totalComments'][$i] = 0;
        $results['totalCode'][$i] = 0;
        while ($stmt->fetch())
        {
            $results['date'][$i] = $date;
            $results['commentsAdded'][$i] = $commentsAdded;
            $results['commentsDeleted'][$i] = $commentsDeleted;
            $results['codeAdded'][$i] = $codeAdded;
            $results['codeDeleted'][$i] = $codeDeleted;

            if ($i > 0)
            {
                $results['totalComments'][$i] = $results['totalComments'][$i - 1];
                $results['totalCode'][$i] = $results['totalCode'][$i - 1];
            }

            $results['totalComments'][$i] += ($results['commentsAdded'][$i] - $results['commentsDeleted'][$i]);
            $results['totalCode'][$i] += ($results['codeAdded'][$i] - $results['codeDeleted'][$i]);

            $i++;
        }

        /* close statement */
        $stmt->close();
    }
    
    return $results;

}

/**
 * Get all of the packages for the project (with repeat)
 * @param $mysqli the mysql connection.
 * @param $user the owner of the repository.
 * @param $repo the repository to get the statistics for.
 */
function getPackages($mysqli, $user, $repo)
{
    $results = array();

    if ($stmt = $mysqli->prepare("SELECT DISTINCT c.commit_date, f.path FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? ORDER BY f.path, c.commit_date"))
    {
        /* bind parameters for markers */
        $stmt->bind_param('ss', $repo, $user);

        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result($date, $package);

        $i = 0;
        while ($stmt->fetch())
        {
            $results[$i] = array();
            $results[$i][0] = $date;
            $results[$i][1] = $package;
            
            $i++;
        }

        /* close statement */
        $stmt->close();
    }
    
    return $results;
}

/**
 * Get all the unique packages that are in the project
 * @param $mysqli the mysql connection.
 * @param $user the owner of the repository.
 * @param $repo the repository to get the statistics for.
 */
function getUniquePackage($mysqli, $user, $repo)
{
    $results = getPackages($mysqli, $user, $repo);

    $packages = array();

    $i = 0;
    foreach ($results as $result)
    {
        if ($i > 0 && $packages[$i-1] != $result[1])
        {
            $packages[$i] = $result[1];
        }
        else if ($i == 0)
        {
            $packages[$i] = $result[1];
        }
        else
        {
            $i--;
        }

        $i++;
    }

    return $packages;
}


?>
