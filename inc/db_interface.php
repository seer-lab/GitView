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

?>