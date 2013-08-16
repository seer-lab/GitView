<?php

require_once '../inc/auth.php';
require_once '../inc/db_interface.php';
require 'Slim/Slim.php';

\Slim\Slim::registerAutoloader();

$app = new \Slim\Slim();

// GET route
$app->get('/commits', 'getCommitsAPI');
$app->get('/commitsChurn/:user/:repo/:group/:path', 'getCommitsChurnAPI');
//$app->get('/commitsChurn/:thre/:user/:repo/', 'getTags');
$app->get('/packages/:user/:repo', 'getRepoPackages');
//$app->get('/pie_stats/:type/:user/:repo/:reverse/:path', 'getPieStats');
$app->get('/stats/:user/:repo/:path', 'getStats');

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

function getCommitsChurnAPI($user, $repo, $group, $path)
{
	global $db_user, $db_pass, $db_stats, $MONTH, $DAY;

	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats . "20_08_05_M");
	
	/* check connection */
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}
	$path = urldecode($path);

	$path = preg_replace('/!/', '/', $path);

	if ($path == "All Packages")
	{
		$path = "";
	}

	#$user = urldecode($user);
	#$repo = urldecode($repo);
	#$group = urldecode($group);

	/* Encode the results as JSON */
	if(isset($group))
	{
		/* Split the repo into its owner and name */
    	//$repo = explode('/', $repo);
		if($group == $MONTH)
		{
			echo json_encode(array(getChurnMonths($mysqli_stats, $user, $repo, $path), getTags($mysqli_stats, $user, $repo)));
		}
		elseif($group == $DAY)
		{
			echo json_encode(array(getChurnDays($mysqli_stats, $user, $repo, $path), getTags($mysqli_stats, $user, $repo)));
		}
		else
		{

			/* On a per commit basis */
			echo json_encode(array(getChurn($mysqli_stats, $user, $repo, $path), getTags($mysqli_stats, $user, $repo)));
		}
	}
}

function getRepoPackages($user, $repo)
{
	global $db_user, $db_pass, $db_stats, $MONTH, $DAY;
	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats . "20_08_05_M");

	/* check connection */
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}
	echo json_encode(getUniquePackage($mysqli_stats, $user, $repo));
}

/*function getPieStats($type, $user, $repo, $reverse, $path)
{
	global $db_user, $db_pass, $db_stats, $MONTH, $DAY;
	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats . "20_08_05_M");

	// check connection
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}

	$path = urldecode($path);

	$path = preg_replace('/!/', '/', $path);

	if ($path == "All Packages")
	{
		$path = "";
	}

    if ($reverse == "false")
    {
        //echo "<p>true</p>";
        $reverse = false;
    }
    else
    {
		$reverse = true;
    }

    if ($type == "topCoder" || $type == "bottomCoders")
    {
		echo json_encode(getTopCoder($mysqli_stats, $user, $repo, $path, $reverse), JSON_NUMERIC_CHECK);
	}
	elseif($type == "topCommenter" || $type == "bottomCommenters")
	{
		echo json_encode(getTopCommenter($mysqli_stats, $user, $repo, $path, $reverse), JSON_NUMERIC_CHECK);
	}
	elseif($type == "topCommitter")
	{
		echo json_encode(getTopCommitter($mysqli_stats, $user, $repo, $path, $reverse), JSON_NUMERIC_CHECK);
	}
	elseif($type == "topAuthor")
	{
		echo json_encode(getTopAuthor($mysqli_stats, $user, $repo, $path, $reverse), JSON_NUMERIC_CHECK);
	}
	elseif($type == "CommentCode")
	{
		echo json_encode(codeRatio($mysqli_stats, $user, $repo, $path), JSON_NUMERIC_CHECK);
	}
}*/

function getStats($user, $repo, $path)
{
	global $db_user, $db_pass, $db_stats, $MONTH, $DAY;
	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats . "20_08_05_M");

	/* check connection */
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}

	$path = urldecode($path);

	$path = preg_replace('/!/', '/', $path);

	if ($path == "All Packages")
	{
		$path = "";
	}

	echo json_encode(array(	'CommentCode' 		=> codeRatio($mysqli_stats, $user, $repo, $path),
							'other'				=> array(
								'topCoder'			=> getTopCoder($mysqli_stats, $user, $repo, $path, false, false),
								'bottomCoder'		=> getTopCoder($mysqli_stats, $user, $repo, $path, true, false),
								'topCommenter'		=> getTopCommenter($mysqli_stats, $user, $repo, $path, false, false),
								'bottomCommenter'	=> getTopCommenter($mysqli_stats, $user, $repo, $path, true, false),
								'topCommitter'		=> getTopCommitter($mysqli_stats, $user, $repo, $path, false),
								'bottomCommitter'	=> getTopCommitter($mysqli_stats, $user, $repo, $path, true),
								'topAuthor'   		=> getTopAuthor($mysqli_stats, $user, $repo, $path, false),
								'bottomAuthor'   	=> getTopAuthor($mysqli_stats, $user, $repo, $path, true),
								'topDeleter'		=> getTopCoder($mysqli_stats, $user, $repo, $path, true, true),
								'bottomDeleter'		=> getTopCoder($mysqli_stats, $user, $repo, $path, false, true),
								'topDeCommenter'	=> getTopCommenter($mysqli_stats, $user, $repo, $path, true, true),
								'bottomDeCommenter'	=> getTopCommenter($mysqli_stats, $user, $repo, $path, false, true))), JSON_NUMERIC_CHECK);
}


/*function getCommitsChurnAPI($thre, $user, $repo)
{
	global $db_user, $db_pass, $db_stats;

	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats );//. $thre);

	// check connection
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}

	echo json_encode();
}*/
?>


