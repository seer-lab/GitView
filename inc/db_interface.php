<?php

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

function getChurn($mysqli)
{
    $results = array(   'date'              => array(),
                        'commentsAdded'     => array(),
                        'commentsDeleted'   => array(),
                        'codeAdded'         => array(),
                        'codeDeleted'       => array()
                    );
    // TODO change to use only 1 repo
    if ($stmt = $mysqli->prepare("SELECT commit_date, total_comment_addition, total_comment_deletion, total_code_addition, total_code_deletion FROM commits ORDER BY commit_date"))
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

function getChurnDays($mysqli)
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


function getChurnMonths($mysqli)
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