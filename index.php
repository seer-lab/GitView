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

require 'inc/auth.php';
require_once 'inc/db_interface.php';

session_start();

include 'templates/header.php';
include 'templates/body.php';

$_SESSION['first_load'] = 0;

/* Connect to the databases */
/*
$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats);

$_SESSION['first_load'] = true;

//$packages = getUniquePackage($mysqli_stats, "ACRA", "acra");
//echo '<option selected="selected">All Packages</option>';

/*foreach ($packages as $package)
{
  echo '<p>' . $package . '</p>';
}*/

// check connection
/*if (mysqli_connect_errno()) {
    printf("Connect failed: %s\n", mysqli_connect_error());
    exit();
}

//getCommits($mysqli_stats);

/* close connection 
$mysqli_stats->close();*/

include 'templates/footer.php';
exit();
?>
