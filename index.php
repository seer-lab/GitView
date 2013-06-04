<?php
require 'inc/auth.php';
require_once 'inc/db_interface.php';

session_start();

include 'templates/header.php';
include 'templates/election-closed.php';

/* Connect to the databases */
$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats);


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
