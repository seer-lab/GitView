<?php
require_once 'inc/auth.php';
require_once 'inc/db_interface.php';
//TODO make db same as the threshold db.
$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats . "20_08_05_M");

global $selectedOwner, $selectedRepo;
?>


<div class="container-fluid" id="seperator">

  <div class="hero-unit">
      <h1>Submit a New Repository</h1>
      <br/>
      <div class="row">
      <!--  Display an error if they entered invalid credentials -->
      <?php
        if (isset($invalid))
        {
          echo '<div class="alert alert-error span8">
                      <button type="button" class="close" data-dismiss="alert">×</button>
                    <strong>Invalid Credentials!</strong> Please enter a valid username and password.
                    </div>';
        }
        ?>
        </div>
      
        <p> Please enter a GitHub user and repository that contains a majority
          of Java code to be visualized</p>

      <form class="form-inline" accept-charset="UTF-8">
        <div class="control-group">
          <div class="controls">
            <input id="username" type="text" placeholder="Username">
            <label class="control-label">/</label>
            <input id="repo" type="text" placeholder="Repository">
          </div>
        </div>
        <button class="btn btn-primary" id='submit' >Submit</button>
      </form>
    </div>
  
    
</div>