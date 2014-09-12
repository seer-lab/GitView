<?php
/*
 * Copyright (c) 2014 Jeremy S. Bradbury, Joseph Heron
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

require_once '../inc/auth.php';
require_once '../inc/db_interface.php';
require 'Slim/Slim.php';

// Allow from any origin
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');    // cache for 1 day
}
// Access-Control headers are received during OPTIONS requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {

    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD']))
        header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");         

    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']))
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
}

\Slim\Slim::registerAutoloader();

$app = new \Slim\Slim();

// GET route
$app->get('/commits', 'getCommitsAPI');
$app->get('/commitsChurn/:user/:repo/:group/:committer/:path', 'getCommitsChurnAPI');
//$app->get('/commitsChurn/:thre/:user/:repo/', 'getTags');
$app->get('/packages/:user/:repo/:commiter', 'getRepoPackages');
$app->get('/committers/:user/:repo/:path', 'getRepoCommitter');
//$app->get('/pie_stats/:type/:user/:repo/:reverse/:path', 'getPieStats');
$app->get('/commits/method/:user/:repo/:committer/:path', 'getMethod');
$app->get('/commits/statement/:user/:repo/:committer/:path', 'getMethodStatement');

// Parse request api calls
$app->get('/stats/:user/:repo/:path', 'getStats');
$app->get('/newrepo/:user/:repo/', 'getNewRepo');

$app->run();

function getMethod($user, $repo, $committer, $path)
{
	global $db_user, $db_pass, $db_stats;

	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats . "20_08_05_M");

	/* check connection */
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}
	$path = cleanPackage($path);
	$committer = cleanUser($committer);

	echo json_encode(array(getMethodChurn($mysqli_stats, $user, $repo, $path, $committer), getTags($mysqli_stats, $user, $repo)));
}

function getMethodStatement($user, $repo, $committer, $path)
{
	global $db_user, $db_pass, $db_stats;

	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats . "20_08_05_M");

	/* check connection */
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}
	$path = cleanPackage($path);
	$committer = cleanUser($committer);

	echo json_encode(array(getMethodStatementChurn($mysqli_stats, $user, $repo, $path, $committer), getTags($mysqli_stats, $user, $repo)));
}

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

function getCommitsChurnAPI($user, $repo, $group, $committer, $path)
{
	global $db_user, $db_pass, $db_stats, $MONTH, $DAY;

	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats . "20_08_05_M");
	
	/* check connection */
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}
	$path = cleanPackage($path);
	$committer = cleanUser($committer);

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
			echo json_encode(array(getChurnMonths($mysqli_stats, $user, $repo, $path, $committer), getTags($mysqli_stats, $user, $repo)));
		}
		elseif($group == $DAY)
		{
			echo json_encode(array(getChurnDays($mysqli_stats, $user, $repo, $path, $committer), getTags($mysqli_stats, $user, $repo)));
		}
		else
		{

			/* On a per commit basis */
			echo json_encode(array(getChurn($mysqli_stats, $user, $repo, $path, $committer), getTags($mysqli_stats, $user, $repo)));
		}
	}
}

function getRepoPackages($user, $repo, $committer)
{
	global $db_user, $db_pass, $db_stats, $MONTH, $DAY;
	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats . "20_08_05_M");

	$committer = cleanUser($committer);

	/* check connection */
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}
	echo json_encode(getUniquePackage($mysqli_stats, $user, $repo, $committer));
}

function getRepoCommitter($user, $repo, $path)
{
	global $db_user, $db_pass, $db_stats, $MONTH, $DAY;
	$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats . "20_08_05_M");

	$path = cleanPackage($path);

	/* check connection */
	if (mysqli_connect_errno()) {
		printf("Connect failed: %s\n", mysqli_connect_error());
		exit();
	}
	echo json_encode(getCommitters($mysqli_stats, $user, $repo, $path));
}

function cleanPackage($path)
{
	$path = urldecode($path);

	$path = preg_replace('/!/', '/', $path);

	if ($path == "All Packages")
	{
		$path = "";
	}
	return $path;
}

function cleanUser($committer)
{
	$committer = urldecode($committer);

	if ($committer == "All Users")
	{
		$committer = "%";
	}
	return $committer;
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
								'topCoder'			=> getTopCoder($mysqli_stats, $user, $repo, $path, false, "addition"),
								'topModified'		=> getTopCoder($mysqli_stats, $user, $repo, $path, false, "modified"),
								'topDeleter'		=> getTopCoder($mysqli_stats, $user, $repo, $path, false, "deletion"),
								'topCommenter'		=> getTopCommenter($mysqli_stats, $user, $repo, $path, false, "addition"),
								'topModCommenter'	=> getTopCommenter($mysqli_stats, $user, $repo, $path, false, "modified"),
								'topDeCommenter'	=> getTopCommenter($mysqli_stats, $user, $repo, $path, false, "deletion"),
								/*'bottomCoder'		=> getTopCoder($mysqli_stats, $user, $repo, $path, true, false),								
								'bottomCommenter'	=> getTopCommenter($mysqli_stats, $user, $repo, $path, true, false),
								'bottomDeleter'		=> getTopCoder($mysqli_stats, $user, $repo, $path, true, true),
								'bottomDeCommenter'	=> getTopCommenter($mysqli_stats, $user, $repo, $path, true, true),*/
								'topCommitter'		=> getTopCommitter($mysqli_stats, $user, $repo, $path, false),
								//'bottomCommitter'	=> getTopCommitter($mysqli_stats, $user, $repo, $path, true),
								'topContributors' => getTopContributors($mysqli_stats, $user, $repo, $path, false),
								/*'bottomAuthor'		=> getTopAuthor($mysqli_stats, $user, $repo, $path, true)*/)), JSON_NUMERIC_CHECK);
}

function getNewRepo($user, $repo)
{
	global $db_user, $db_pass, $db_data, $MONTH, $DAY;
	$mysqli_data = new mysqli("localhost", $db_user, $db_pass, $db_data);

	$user = urldecode($user);
	$repo = urldecode($repo);

	//Validate both repo and user
	if(validateUserRepo($user, $repo) === TRUE)
	{
		// check if the user/repo hasnt already been parsed
		if(isUniqueRepo($mysqli_data, $user, $repo) === FALSE)
		{
			//$output = system('bash ../src/scraper ' . $user . ' ' . $repo);

			// If the scrap is successful parse otherwise return an error
			//echo json_encode($output);

			// If the parse is unsuccessful return 

			//TODO set up a queue to allow for syncronize requests.
		}
		else
		{
			// User/Repo aready parsed error
		}
	}
	else
	{
		// User/Repo are not valid error
	}
}

function validateUserRepo($user, $repo)
{
	//Username == alphanumeric with dashes (just not at the beginning)
	//Repo can only be alphanumeric (with dashes, underscores, periods)
	if(preg_match("/^[a-zA-Z0-9][a-zA-Z0-9-]*$/", $user) === 1)
	{
		if(preg_match("/^[a-zA-Z0-9-_\.]+$/", $repo) === 1)
		{
			return TRUE;
		}
	}
	return FALSE;
}

?>


