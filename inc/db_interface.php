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
    $results = array(   'date'                  => array(),
                        'commentsAdded'         => array(),
                        'commentsDeleted'       => array(),
                        'commentsModified'      => array(),
                        'codeAdded'             => array(),
                        'codeDeleted'           => array(),
                        'codeModified'          => array(),
                        'totalComments'         => array(),
                        'totalCommentsModified' => array(),
                        'totalCode'             => array(),
                        'totalCodeModified'     => array(),
                    );
    // TODO change to use only 1 repo
    if ($stmt = $mysqli->prepare("SELECT DISTINCT c.commit_date, c.total_comment_addition, c.total_comment_deletion, c.total_comment_modified, c.total_code_addition, c.total_code_deletion, c.total_code_modified FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN file AS f ON c.commit_id = f.commit_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? AND f.path LIKE ? ORDER BY c.commit_date"))
    
    {       
        $path = $path . '%';
        /* bind parameters for markers */
        $stmt->bind_param('sss', $repo, $user, $path);

        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result($date, $commentsAdded, $commentsDeleted, $commentsModified, $codeAdded, $codeDeleted, $codeModified);

        $i = 0;
        $results['totalComments'][$i] = 0;
        $results['totalCode'][$i] = 0;
        $results['totalCommentsModified'][$i] = 0;
        $results['totalCodeModified'][$i] = 0;
        while ($stmt->fetch())
        {
            $results['date'][$i] = $date;
            $results['commentsAdded'][$i] = $commentsAdded;
            $results['commentsDeleted'][$i] = $commentsDeleted;
            $results['commentsModified'][$i] = $commentsModified;
            $results['codeAdded'][$i] = $codeAdded;
            $results['codeDeleted'][$i] = $codeDeleted;
            $results['codeModified'][$i] = $codeModified;

            if ($i > 0)
            {
                $results['totalComments'][$i] = $results['totalComments'][$i - 1];
                $results['totalCode'][$i] = $results['totalCode'][$i - 1];

                $results['totalCommentsModified'][$i] = $results['totalCommentsModified'][$i - 1];
                $results['totalCodeModified'][$i] = $results['totalCodeModified'][$i - 1];
            }

            $results['totalComments'][$i] += ($results['commentsAdded'][$i] - $results['commentsDeleted'][$i]);
            $results['totalCode'][$i] += ($results['codeAdded'][$i] - $results['codeDeleted'][$i]);
            $results['totalCommentsModified'][$i] += $results['commentsModified'][$i];
            $results['totalCodeModified'][$i] += $results['codeModified'][$i];
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
    $results = array(   'date'                  => array(),
                        'commentsAdded'         => array(),
                        'commentsDeleted'       => array(),
                        'commentsModified'      => array(),
                        'codeAdded'             => array(),
                        'codeDeleted'           => array(),
                        'codeModified'          => array(),
                        'totalComments'         => array(),
                        'totalCommentsModified' => array(),
                        'totalCode'             => array(),
                        'totalCodeModified'     => array(),
                    );

    if ($stmt = $mysqli->prepare("SELECT DATE(c.commit_date), SUM(c.total_comment_addition), SUM(c.total_comment_deletion), SUM(c.total_comment_modified), SUM(c.total_code_addition), SUM(c.total_code_deletion), SUM(c.total_code_modified) FROM commits AS c WHERE c.commit_id IN (SELECT DISTINCT c2.commit_id FROM commits AS c2 INNER JOIN repositories AS r ON r.repo_id = c2.repo_reference INNER JOIN file AS f2 ON c2.commit_id = f2.commit_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? AND f2.path LIKE ?) GROUP BY DATE(commit_date) ORDER BY c.commit_date"))
    {
        $path = $path . '%';
        /* bind parameters for markers */
        $stmt->bind_param('sss', $repo, $user, $path);

        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result($date, $commentsAdded, $commentsDeleted, $commentsModified, $codeAdded, $codeDeleted, $codeModified);

        $i = 0;
        $results['totalComments'][$i] = 0;
        $results['totalCode'][$i] = 0;
        $results['totalCommentsModified'][$i] = 0;
        $results['totalCodeModified'][$i] = 0;
        while ($stmt->fetch())
        {
            $results['date'][$i] = $date;
            $results['commentsAdded'][$i] = $commentsAdded;
            $results['commentsDeleted'][$i] = $commentsDeleted;
            $results['commentsModified'][$i] = $commentsModified;
            $results['codeAdded'][$i] = $codeAdded;
            $results['codeDeleted'][$i] = $codeDeleted;
            $results['codeModified'][$i] = $codeModified;

            if ($i > 0)
            {
                $results['totalComments'][$i] = $results['totalComments'][$i - 1];
                $results['totalCode'][$i] = $results['totalCode'][$i - 1];

                $results['totalCommentsModified'][$i] = $results['totalCommentsModified'][$i - 1];
                $results['totalCodeModified'][$i] = $results['totalCodeModified'][$i - 1];
            }

            $results['totalComments'][$i] += ($results['commentsAdded'][$i] - $results['commentsDeleted'][$i]);
            $results['totalCode'][$i] += ($results['codeAdded'][$i] - $results['codeDeleted'][$i]);
            $results['totalCommentsModified'][$i] += $results['commentsModified'][$i];
            $results['totalCodeModified'][$i] += $results['codeModified'][$i];
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
    $results = array(   'date'                  => array(),
                        'commentsAdded'         => array(),
                        'commentsDeleted'       => array(),
                        'commentsModified'      => array(),
                        'codeAdded'             => array(),
                        'codeDeleted'           => array(),
                        'codeModified'          => array(),
                        'totalComments'         => array(),
                        'totalCommentsModified' => array(),
                        'totalCode'             => array(),
                        'totalCodeModified'     => array(),
                    );

    if ($stmt = $mysqli->prepare("SELECT DATE_FORMAT(c.commit_date, '%Y-%m'), SUM(c.total_comment_addition), SUM(c.total_comment_deletion), SUM(c.total_comment_modified), SUM(c.total_code_addition), SUM(c.total_code_deletion), SUM(c.total_code_modified) FROM commits AS c WHERE c.commit_id IN (SELECT DISTINCT c2.commit_id FROM commits AS c2 INNER JOIN repositories AS r ON r.repo_id = c2.repo_reference INNER JOIN file AS f2 ON c2.commit_id = f2.commit_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? AND f2.path LIKE ?) GROUP BY DATE_FORMAT(commit_date, '%Y-%m') ORDER BY c.commit_date"))
    {
        $path = $path . '%';
        /* bind parameters for markers */
        $stmt->bind_param('sss', $repo, $user, $path);

        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result($date, $commentsAdded, $commentsDeleted, $commentsModified, $codeAdded, $codeDeleted, $codeModified);

        $i = 0;
        $results['totalComments'][$i] = 0;
        $results['totalCode'][$i] = 0;
        $results['totalCommentsModified'][$i] = 0;
        $results['totalCodeModified'][$i] = 0;
        while ($stmt->fetch())
        {
            $results['date'][$i] = $date;
            $results['commentsAdded'][$i] = $commentsAdded;
            $results['commentsDeleted'][$i] = $commentsDeleted;
            $results['commentsModified'][$i] = $commentsModified;
            $results['codeAdded'][$i] = $codeAdded;
            $results['codeDeleted'][$i] = $codeDeleted;
            $results['codeModified'][$i] = $codeModified;

            if ($i > 0)
            {
                $results['totalComments'][$i] = $results['totalComments'][$i - 1];
                $results['totalCode'][$i] = $results['totalCode'][$i - 1];

                $results['totalCommentsModified'][$i] = $results['totalCommentsModified'][$i - 1];
                $results['totalCodeModified'][$i] = $results['totalCodeModified'][$i - 1];
            }

            $results['totalComments'][$i] += ($results['commentsAdded'][$i] - $results['commentsDeleted'][$i]);
            $results['totalCode'][$i] += ($results['codeAdded'][$i] - $results['codeDeleted'][$i]);
            $results['totalCommentsModified'][$i] += $results['commentsModified'][$i];
            $results['totalCodeModified'][$i] += $results['codeModified'][$i];
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
 *  - /src/
 *  - /src/org/
 *  - /src/org/test
 *  - /src/org/main
 *  - /src/lists
 */
function getParentPackages($packages)
{
    //$tempArray = $package;
    $results = $packages;

    $i = 0;
    while ($i < sizeof($results))
    {
        $newList = checkForMore($results, $results[$i], $i);

        if ($newList != NULL)
        {
            array_splice($results, $i, 0, $newList);

            $i += sizeof($newList);
        }
        else
        {
            $i++;
        }        
    }

    return $results;
}

/**
 * Recursively searches the given package for parent packages
 * Once the package is the highest package in its tree or is
 * already contained in the list of packages null will be returned
 * @param $packages the list of packages already known
 * @param $package the package currently being parsed
 * @return The new list of packages contaning packages found or NULL if no packages were found
 */
function checkForMore($packages, $package)
{
    preg_match_all("/(.*\/).+\//", $package, $list);
    if (isset($list) && isset($list[1]) && isset($list[1][0]))
    {
        if (!in_array($list[1][0], $packages))
        {
            //echo "<p>newList " . $list[1][0] . "</p>";
            $secondPart = $list[1][0];
            $returnList = checkForMore($packages, $list[1][0]);

            if ($returnList != NULL)
            {
                //echo "<p>val " . $secondPart . "</p>";
                return array_merge($returnList, (array)$secondPart);
            }
            else
            {
                //echo "<p>valE " . $secondPart . "</p>";
                return array($secondPart);
            }
        }
    }
    return NULL;
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
            //echo "<p>actual " . $result[0] . "</p>";
        }
        else if ($i == 0)
        {
            $packages[$i] = $result[0];
            //echo "<p>actual " . $result[0] . "</p>";
        }
        else
        {
            $i--;
        }

        $i++;
    }

    return getParentPackages($packages);
}

function getUser()
{
    
}


function getTags($mysqli, $user, $repo)
{
    $results = array(   'date'          => array(),
                        'name'          => array(),
                        'description'   => array(),
                        'sha'           => array());
    if ($stmt = $mysqli->prepare("SELECT t.tag_name, t.tag_description, t.tag_date, t.tag_sha FROM repositories AS r INNER JOIN tags AS t ON r.repo_id = t.repo_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? ORDER BY t.tag_date"))
    {
        /* bind parameters for markers */
        $stmt->bind_param('ss', $repo, $user);

        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result($name, $desc, $date, $sha);


        $i = 0;
        while ($stmt->fetch())
        {
            //echo "<p>date " . $date . "</p>";
            $results['date'][$i] = $date;
            $results['desc'][$i] = $desc;
            $results['name'][$i] = $name;
            $results['sha'][$i] = $sha;
            
            $i++;
        }

        /* close statement */
        $stmt->close();
    }
    
    return $results;
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
