<?php
require_once 'inc/auth.php';
require_once 'inc/db_interface.php';
//TODO make db same as the threshold db.
$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats . "20_08_05_M");

global $selectedOwner, $selectedRepo;
?>

<div class="container-fluid" id="container" style="width:100%; height:700px;"></div>

<div class="container-fluid" id="seperator">
   <div class="row-fluid">
    <div class="span6">
<form class="form-horizontal" accept-charset="UTF-8">
      <div class="control-group">
          <label for="repo" class="control-label">Repository</label>
              <div class="controls">
                <select id="repo" name="repo" class="input-xlarge">

                    <?php
			                  global $selectedOwner, $selectedRepo;
                        /** Create an entry for each repo */
                        $repos = getAllRepos($mysqli_stats);

                        $selected = true;
                        $option = '';
                        foreach ($repos as $repo)
                        {
                            if ($selected)
                            {
                                $option = '<option selected="selected">';
                        				$selectedOwner = $repo['repo_owner'];
                        				$selectedRepo = $repo['repo_name'];
                                $selected = false;
                            }
                            else
                            {
                                $option = '<option>';
                            }
                            echo $option . $repo['repo_owner'] . "/" . $repo['repo_name'] . '</option>';
                        }
                    ?>
                </select>
            </div>
        </div>    
      <div class="control-group">
          <label for="group" class="control-label">Group</label>
              <div class="controls">
                <select id="group" name="group" class="input-xlarge">
                    <?php
                        /*
                         * Options will be:
                         * - Month
                         * - Day
                         * - Commit (None)
                         */

                        echo '<option selected="selected">' . $MONTH . '</option>';
                        echo '<option>' . $DAY . '</option>';
                        echo '<option>' . $COMMIT . '</option>';
                        
                    ?>
                </select>
            </div>
        </div>
      <div class="control-group">
          <label for="package" class="control-label">Package</label>
              <div class="controls">
                <select id="package" name="package" class="input-xlarge">
                    <?php
                      global $selectedOwner, $selectedRepo;
                      //SET TO load up only on first load

                      echo '<option selected="selected">All Packages</option>';
                      if ($_SESSION['first_load'] == 0)
                      {
                        $_SESSION['first_load'] = 1;
			                  

			                  $packages = getUniquePackage($mysqli_stats, $selectedOwner, $selectedRepo);
                        //echo '<option selected="selected">All Packages</option>';
                       
                        foreach ($packages as $package)
                        {
                          echo '<option>' . $package . '</option>';
                        }
                      }
                        
                    ?>
                </select>
            </div>
        </div>
        <div class="control-group">
          <label for="committer" class="control-label">Committer</label>
              <div class="controls">
                <select id="committer" name="committer" class="input-xlarge">
                    <?php
                      global $selectedOwner, $selectedRepo;
                      //SET TO load up only on first load

                      echo '<option selected="selected">All Users</option>';
                      if ($_SESSION['first_load'] == 1)
                      {
                        $_SESSION['first_load'] = 2;
                        

                        $packages = getCommitters($mysqli_stats, $selectedOwner, $selectedRepo);
                        
                       
                        foreach ($packages as $package)
                        {
                          echo '<option>' . $package . '</option>';
                        }
                      }
                        
                    ?>
                </select>
            </div>
        </div>
        <div class="control-group">
          <div class="controls">
              <button class="btn btn-primary" id='update' >Refine</button>
              <button class="btn btn-primary" id='reset' >Reset</button>
          </div>
        </div>
</form>
</div>
  <div class="span6">
    <div class="panel" id="commit_info_panel">
        <div class="panel-heading">
          <h3 class="panel-title" id="commit_panel_title">Commit Information</h3>
        </div>
        <p id="commit_message"> MODIFIED: a lot of codes and comments</p>
      </div>
   </div>
 </div>
  
</div>

<div class="container-fluid" id="seperator">
   <div class="row-fluid">
    <div class="span5">
      <div class="container-fluid" id="code_pie" style="min-width: 310px; height: 400px" ></div>
      <table class="table">
        <thead>
          <th>Top Committers</th>
          <th>Top Contributors</th>
        </thead>
        <tbody id="CommitAuthor">
        </tbody>
      </table>
    </div>

    <div class="span7" >
      <table class="table">
        <thead>
          <th>Top Coders</th>
          <th>Top Modifiers</th>
          <th>Top Deleters</th>
        </thead>
        <tbody id="CodeComment">
        </tbody>
        <thead>
          <th>Top Commenters</th>
          <th>Top Comment Modifiers</th>
          <th>Top Comment Deleters</th>
        </thead>
        <tbody id="Deleters">
        </tbody>
        <!--<thead>
          <th>Bottom Coders</th>
          <th>Bottom Commenters</th>
          <th>Bottom Deleters</th>
          <th>Bottom Comment Deleters</th>
        </thead>
        <tbody id="mod">
        </tbody>
        </-->
      </table>
    </div>

  </div>
</div>
<!--<form class="form-horizontal" accept-charset="UTF-8">
      <div class="control-group">
          <label for="pie_type" class="control-label">Graph</label>
              <div class="controls">
                <select id="pie_type" name="" class="input-xlarge">
                    <?php
                        //echo '<option selected="selected">Comment To Code</option>';
                    ?>
                </select>
            </div>
        </div>
</form> </-->
