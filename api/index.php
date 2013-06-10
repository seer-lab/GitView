<?php

require_once '../inc/auth.php';
require_once '../inc/db_interface.php';
require 'Slim/Slim.php';

\Slim\Slim::registerAutoloader();

$app = new \Slim\Slim();

// GET route
$app->get('/commits', 'getCommitsAPI');
$app->get('/commitsChurn/:user/:repo/:position', 'getCommitsChurnAPI');


$app->run();

function getCommitsAPI()
{
	global $db_user, $db_pass, $db_stats;
	
	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats);
	
	/* check connection */
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}
	
	/* Encode the results as JSON */
	echo json_encode(getCommitsMonths($mysqli_stats));
}

function getCommitsChurnAPI($user, $repo, $group)
{
	global $db_user, $db_pass, $db_stats;
	
	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats);
	
	/* check connection */
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}
	
	/* Encode the results as JSON */
	if(isset($group))
	{
		/* Split the repo into its owner and name */
    	//$repo = explode('/', $repo);
		if($group == $MONTH)
		{
			echo json_encode(getChurnMonths($mysqli_stats, $user, $repo));
		}
		elseif($group == $DAY)
		{
			echo json_encode(getChurnDays($mysqli_stats, $user, $repo));
		}
		else
		{
			/* On a per commit basis */
			echo json_encode(getChurn($mysqli_stats, $user, $repo));
		}
	}
}