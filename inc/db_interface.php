<?php

function getCommits($mysqli)
{
    $results = array(   'date'      => array(),
                        'comments'  => array(),
                        'code'      => array()
                    );
    // TODO change to use only 1 repo
	if ($stmt = $mysqli_elections->prepare("SELECT date, total_comments, total_code FROM commits ORDER BY commit_date"))
	{
		/* execute query */
		$stmt->execute();

        /* bind result variables */
        $stmt->bind_result($date, $comment, $code);

        $i = 0;
        while ($stmt->fetch())
        {
            $result['date'][i] = $date;
            $result['comment'][i] = $comment;
            $result['code'][i] = $code;
            $i++;
        }

		/* close statement */
		$stmt->close();
	}
    
    return $results;
}

?>