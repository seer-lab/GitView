<?php

?>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Github Mining Project</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Github Mining Project Commits Graph">
    <meta name="author" content="Github Mining Project">

    <!-- CSS styles -->
    <style type="text/css">
      body {
        padding-top: 60px;
        padding-bottom: 20px;
      }
    </style>
    <link href="../css/smoothness/jquery-ui-1.10.3.custom.min.css" rel="stylesheet" />
    <style type="text/css">
    </style>
    <link href="../css/bootstrap.min.css" rel="stylesheet">
    <link href="../css/bootstrap-responsive.min.css" rel="stylesheet">

    <!-- HTML5 shiv, for IE6-8 support of HTML5 elements -->
    <!--[if lt IE 9]>
      <script src="js/html5shiv.min.js"></script>
    <![endif]-->
  </head>
  <body>
    <div class="navbar navbar-inverse navbar-fixed-top">
      <div class="navbar-inner">
        <div class="container">
          <!-- GitView Visualizing  -->
          <a class="brand" href="../index.php">
            GitView Visualizing
          </a> 
          
            <?php
              if(preg_match("/\/(index.php)?.*/", $_SERVER['REQUEST_URI'])){
                echo '<ul class="nav pull-right">';
                //echo '<ul class="">';
                echo '<a class="brand" href="../add_new.php">Add New</a>';
                //echo '</ul>';
                echo '</ul>';
              }
            ?>
            <ul class="nav pull-right"> 
            <!-- <a class="brand" href="">About</a> -->
            </ul>
        </div>
      </div>
    </div>
    <div class="container">
