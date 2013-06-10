<?php

function getAllRepos($mysqli)
{
     $results = array(array('repo_name'   => "",
                            'repo_owner'  => ""
                     ));

    if ($stmt = $mysqli->prepare("SELECT repo_name, repo_owner FROM repositories"))
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

function getCommits($mysqli)
{
    $results = array(   'date'      => array(),
                        'comments'  => array(),
                        'code'      => array()
                    );
    // TODO change to use only 1 repo
	if ($stmt = $mysqli->prepare("SELECT commit_date, total_comments, total_code FROM commits ORDER BY commit_date"))
	{
		/* execute query */
		$stmt->execute();

        /* bind result variables */
        $stmt->bind_result($date, $comment, $code);

        $i = 0;
        while ($stmt->fetch())
        {
            $results['date'][$i] = $date;
            $results['comments'][$i] = $comment;
            $results['code'][$i] = $code;
            $i++;
        }

		/* close statement */
		$stmt->close();
	}
    
    return $results;
}

function getCommitsMonths($mysqli)
{
    $results = array(   'date'      => array(),
                        'comments'  => array(),
                        'code'      => array()
                    );
    // TODO change to use only 1 repo
    if ($stmt = $mysqli->prepare("SELECT DATE(commit_date), SUM(total_comments), SUM(total_code) FROM commits GROUP BY DATE(commit_date) ORDER BY commit_date"))
    {
        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result($date, $comment, $code);

        $i = 0;
        while ($stmt->fetch())
        {
            $results['date'][$i] = $date;
            $results['comments'][$i] = $comment;
            $results['code'][$i] = $code;
            $i++;
        }

        /* close statement */
        $stmt->close();
    }
    
    return $results;
}

function getChurn($mysqli, $user, $repo)
{
    $results = array(   'date'              => array(),
                        'commentsAdded'     => array(),
                        'commentsDeleted'   => array(),
                        'codeAdded'         => array(),
                        'codeDeleted'       => array()
                    );
    // TODO change to use only 1 repo
    if ($stmt = $mysqli->prepare("SELECT c.commit_date, c.total_comment_addition, c.total_comment_deletion, c.total_code_addition, c.total_code_deletion FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? ORDER BY c.commit_date"))
    {
        /* execute query */
        $stmt->execute($user, $repo);

        /* bind result variables */
        $stmt->bind_result($date, $commentsAdded, $commentsDeleted, $codeAdded, $codeDeleted);

        $i = 0;
        while ($stmt->fetch())
        {
            $results['date'][$i] = $date;
            $results['commentsAdded'][$i] = $commentsAdded;
            $results['commentsDeleted'][$i] = $commentsDeleted;
            $results['codeAdded'][$i] = $codeAdded;
            $results['codeDeleted'][$i] = $codeDeleted;
            $i++;
        }

        /* close statement */
        $stmt->close();
    }
    
    return $results;

}

function getChurnDays($mysqli, $user, $repo)
{
    $results = array(   'date'              => array(),
                        'commentsAdded'     => array(),
                        'commentsDeleted'   => array(),
                        'codeAdded'         => array(),
                        'codeDeleted'       => array()
                    );
    // TODO change to use only 1 repo
    if ($stmt = $mysqli->prepare("SELECT DATE(commit_date), SUM(total_comment_addition), SUM(total_comment_deletion), SUM(total_code_addition), SUM(total_code_deletion) FROM commits GROUP BY DATE(commit_date) ORDER BY commit_date"))
    {
        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result($date, $commentsAdded, $commentsDeleted, $codeAdded, $codeDeleted);

        $i = 0;
        while ($stmt->fetch())
        {
            $results['date'][$i] = $date;
            $results['commentsAdded'][$i] = $commentsAdded;
            $results['commentsDeleted'][$i] = $commentsDeleted;
            $results['codeAdded'][$i] = $codeAdded;
            $results['codeDeleted'][$i] = $codeDeleted;
            $i++;
        }

        /* close statement */
        $stmt->close();
    }
    
    return $results;

}


function getChurnMonths($mysqli, $user, $repo)
{
    $results = array(   'date'              => array(),
                        'commentsAdded'     => array(),
                        'commentsDeleted'   => array(),
                        'codeAdded'         => array(),
                        'codeDeleted'       => array()
                    );
    // TODO change to use only 1 repo
    if ($stmt = $mysqli->prepare("SELECT DATE_FORMAT(commit_date, '%Y-%m'), SUM(total_comment_addition), SUM(total_comment_deletion), SUM(total_code_addition), SUM(total_code_deletion) FROM commits GROUP BY DATE_FORMAT(commit_date, '%Y-%m') ORDER BY commit_date"))
    {
        /* execute query */
        $stmt->execute();

        /* bind result variables */
        $stmt->bind_result($date, $commentsAdded, $commentsDeleted, $codeAdded, $codeDeleted);

        $i = 0;
        while ($stmt->fetch())
        {
            $results['date'][$i] = $date;
            $results['commentsAdded'][$i] = $commentsAdded;
            $results['commentsDeleted'][$i] = $commentsDeleted;
            $results['codeAdded'][$i] = $codeAdded;
            $results['codeDeleted'][$i] = $codeDeleted;
            $i++;
        }

        /* close statement */
        $stmt->close();
    }
    
    return $results;

}

?>