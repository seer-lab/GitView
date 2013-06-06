<?php

require_once '../inc/auth.php';
require_once '../inc/db_interface.php';
require 'Slim/Slim.php';

\Slim\Slim::registerAutoloader();

$app = new \Slim\Slim();

// GET route
$app->get('/commits', 'getCommitsAPI');
$app->get('/commitsChurn', 'getCommitsChurnAPI');


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

function getCommitsChurnAPI()
{
	global $db_user, $db_pass, $db_stats;
	
	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats);
	
	/* check connection */
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}
	
	/* Encode the results as JSON */
	echo json_encode(getChurn($mysqli_stats));
}