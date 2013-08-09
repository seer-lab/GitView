<?php
require_once 'inc/auth.php';
require_once 'inc/db_interface.php';
//TODO make db same as the threshold db.
$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats . "20_08_05_M");

global $selectedOwner, $selectedRepo;
?>

<div class="container-fluid" id="container" style="width:100%; height:500px;"></div>

<div class="container-fluid" id="seperator">
   <div class="row-fluid">
    <div class="span6">
<form class="form-horizontal" accept-charset="UTF-8">
      <div class="control-group">
          <label for="threshold" class="control-label">Threshold</label>
              <div class="controls">
                <select id="threshold" name="threshold" class="input-xlarge">

                    <?php
                        $thresholds = array();
                        //$thresholds[0] = "05";
                        //$thresholds[1] = "05_M";
                        //$thresholds[2] = "10";
                        //$thresholds[3] = "10_M";
                        $thresholds[0] = "20_08_05_M";

                        $selected = true;
                        $option = '';
                        foreach ($thresholds as $threshold)
                        {
                            if ($selected)
                            {
                                $option = '<option selected="selected">';
                                $selected = false;
                            }
                            else
                            {
                                $option = '<option>';
                            }

                            if ($threshold == "05")
                            {
                              $value = "0.5";
                            }
                            elseif ($threshold == "05_M")
                            {
                              $value = "0.5 M";
                            }                            
                            elseif ($threshold == "10")
                            {
                              $value = "1.0";
                            }
                            elseif ($threshold == "10_M")
                            {
                              $value = "1.0 M";
                            }
                            elseif ($threshold == "20_08_05_M")
                            {
                              $value = "S = 20, H = 0.8, L = 0.5 M";
                            }
                            echo $option . $value . '</option>';
                        }
                    ?>
                </select>
            </div>
        </div> 
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
                      if ($_SESSION['first_load'])
                      {
                        $_SESSION['first_load'] = false;
			                  

			                  $packages = getUniquePackage($mysqli_stats, $selectedOwner, $selectedRepo);
                        echo '<option selected="selected">All Packages</option>';
                       
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
            <button class="btn btn-primary" id='update' >Submit</button>
          </div>
        </div>
</form>
</div>
    <div class="panel" id="commit_info_panel">
        <div class="panel-heading">
          <h3 class="panel-title" id="commit_panel_title">Commit Information</h3>
        </div>
        <p id="commit_message"> MODIFIED: a lot of codes and comments</p>
      </div>
   </div>
</div>

<div class="container-fluid" id="code_pie" style="min-width: 310px; height: 400px" ></div>