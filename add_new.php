<?php
require 'inc/auth.php';
require_once 'inc/db_interface.php';

session_start();

include 'templates/request_header.php';
include 'templates/request.php';


include 'templates/request_footer.php';
exit();
?>