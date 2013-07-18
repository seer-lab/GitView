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
function getChurn($mysqli, $user, $repo, $path)
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
    if ($stmt = $mysqli->prepare("SELECT DISTINCT c.commit_date, c.total_comment_addition, c.total_comment_deletion, c.total_code_addition, c.total_code_deletion FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? AND f.path LIKE ? ORDER BY c.commit_date"))
    
    {       
        $path = $path . '%';
        /* bind parameters for markers */
        $stmt->bind_param('sss', $repo, $user, $path);

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
function getChurnDays($mysqli, $user, $repo, $path)
{
    $results = array(   'date'              => array(),
                        'commentsAdded'     => array(),
                        'commentsDeleted'   => array(),
                        'codeAdded'         => array(),
                        'codeDeleted'       => array(),
                        'totalComments'     => array(),
                        'totalCode'         => array()
                    );

    if ($stmt = $mysqli->prepare("SELECT DATE(c.commit_date), SUM(c.total_comment_addition), SUM(c.total_comment_deletion), SUM(c.total_code_addition), SUM(c.total_code_deletion)FROM commits AS c WHERE c.commit_id IN (SELECT DISTINCT c2.commit_id FROM commits AS c2 INNER JOIN repositories AS r ON r.repo_id = c2.repo_reference INNER JOIN file AS f2 ON c2.commit_id = f2.commit_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? AND f2.path LIKE ?) GROUP BY DATE(commit_date) ORDER BY c.commit_date"))
    {
        $path = $path . '%';
        /* bind parameters for markers */
        $stmt->bind_param('sss', $repo, $user, $path);

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
function getChurnMonths($mysqli, $user, $repo, $path)
{
    $results = array(   'date'              => array(),
                        'commentsAdded'     => array(),
                        'commentsDeleted'   => array(),
                        'codeAdded'         => array(),
                        'codeDeleted'       => array(),
                        'totalComments'     => array(),
                        'totalCode'         => array()
                    );

    if ($stmt = $mysqli->prepare("SELECT DATE_FORMAT(c.commit_date, '%Y-%m'), SUM(c.total_comment_addition), SUM(c.total_comment_deletion), SUM(c.total_code_addition), SUM(c.total_code_deletion) FROM commits AS c WHERE c.commit_id IN (SELECT DISTINCT c2.commit_id FROM commits AS c2 INNER JOIN repositories AS r ON r.repo_id = c2.repo_reference INNER JOIN file AS f2 ON c2.commit_id = f2.commit_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? AND f2.path LIKE ?) GROUP BY DATE_FORMAT(commit_date, '%Y-%m') ORDER BY c.commit_date"))
    {
        $path = $path . '%';
        /* bind parameters for markers */
        $stmt->bind_param('sss', $repo, $user, $path);

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

    if ($stmt = $mysqli->prepare("SELECT DISTINCT f.path FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? ORDER BY f.path, c.commit_date"))
    {
        /* bind parameters for markers */
        $stmt->bind_param('ss', $repo, $user);

        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result( $package);

        $i = 0;
        while ($stmt->fetch())
        {
            $results[$i] = array();
            $results[$i][0] = $package;
            
            $i++;
        }

        /* close statement */
        $stmt->close();
    }
    
    return $results;
}

/**
 * Break down the list of packages to get the packages that are
 * only expressed as part of another package.
 * @param $package The list of packages for find more packages from
 * @return the next list of packages, for example list main
 * contain:
 *  - /src/org/test
 *  - /src/org/main
 *  - /src/lists
 * would return:
 *  - /src/org/
 *  - /src/
 *  - /src/org/test
 *  - /src/org/main
 *  - /src/lists
 */
function getParentPackages($package)
{
    //$tempArray = $package;
    $results = $package;

    $i = 0;
    while ($i < sizeof($results))
    {
        preg_match_all("/(.*\/).+\//", $results[$i], $list);
        if (isset($list) && isset($list[1]) && isset($list[1][0]))
        {
            if (!in_array($list[1][0], $results))
            {
                //echo "<p>list " . $list[1][0] . "</p>";
                array_splice($results, $i+1, 0, $list[1][0]);
                
                //echo "<p>results " . $results[$i+1] . "</p>";
            }
            //array_push($result, $list);
        }
        //echo "<p>" . $results[$i] . "</p>";
        $i++;
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
        if ($i > 0 && $packages[$i-1] != $result[0])
        {
            $packages[$i] = $result[0];
        }
        else if ($i == 0)
        {
            $packages[$i] = $result[0];
        }
        else
        {
            $i--;
        }

        $i++;
    }

    return getParentPackages($packages);
}

function getClasses($mysqli, $user, $repo, $package)
{
    $results = array();

    if ($stmt = $mysqli->prepare("SELECT DISTINCT f.name FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? AND f.path LIKE ? ORDER BY f.name, c.commit_date"))
    {
        /* bind parameters for markers */
        $stmt->bind_param('sss', $repo, $user, $package);

        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result( $package);

        $i = 0;
        while ($stmt->fetch())
        {
            $results[$i] = array();
            $results[$i][0] = $package;
            
            $i++;
        }

        /* close statement */
        $stmt->close();
    }
    
    return $results;
}

?>
