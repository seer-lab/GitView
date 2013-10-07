<?php
require 'inc/auth.php';
require_once 'inc/db_interface.php';

session_start();

include 'templates/header.php';
include 'templates/body.php';

$_SESSION['first_load'] = 0;

/* Connect to the databases */
/*
$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats ."20_08_05_M");

$_SESSION['first_load'] = true;

$packages = getUniquePackage($mysqli_stats, "ACRA", "acra");
echo '<option selected="selected">All Packages</option>';

foreach ($packages as $package)
{
  echo '<p>' . $package . '</p>';
}

// check connection
if (mysqli_connect_errno()) {
    printf("Connect failed: %s\n", mysqli_connect_error());
    exit();
}*/

//getCommits($mysqli_stats);

/* close connection */
$mysqli_stats->close();

include 'templates/footer.php';
exit();
?>
