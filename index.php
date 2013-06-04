<?php
require 'inc/auth.php';

session_start();


/* Connect to the databases */
$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats);


/* check connection */
if (mysqli_connect_errno()) {
    printf("Connect failed: %s\n", mysqli_connect_error());
    exit();
}


/* close connection */
$mysqli_stats->close();

#include 'templates/footer.php';
exit();
?>
