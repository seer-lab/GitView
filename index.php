<?php
require 'inc/auth.php';
require_once 'inc/db_interface.php';

session_start();

include 'templates/header.php';
include 'templates/body.php';

/* Connect to the databases */
$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats);

$repos = getAllRepos($mysqli_stats);

/* Check that the post is set */
/*if (!isset($_POST['repo']) && !isset($_POST['group']) && isset($repos))
{
    /* Set to first repo /
    $_POST['repo'] = $repos[0]['repo_owner'] . "/" . $repos[0]['repo_name'];
    $_POST['group'] = 'Month';
    echo $_POST['repo'];
    echo $_POST['group'];
}


if (isset($_POST['repo']) && isset($_POST['group']))
{
    
}*/

//echo $_POST['repo'];
//echo $_POST['group'];

/* check connection */
if (mysqli_connect_errno()) {
    printf("Connect failed: %s\n", mysqli_connect_error());
    exit();
}

//getCommits($mysqli_stats);

/* close connection */
$mysqli_stats->close();

include 'templates/footer.php';
exit();
?>
