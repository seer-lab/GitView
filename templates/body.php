<?php
require_once 'inc/auth.php';
require_once 'inc/db_interface.php';

$mysqli_stats = new mysqli("localhost", $db_user, $db_pass, $db_stats);
?>

<div class="row" id="container" style="width:100%; height:500px;"></div>

<form class="form-horizontal" accept-charset="UTF-8">
      <div class="control-group">
          <label for="repo" class="control-label">Repository</label>
              <div class="controls">
                <select id="repo" name="repo" class="input-xlarge">

                    <?php
                        /** Create an entry for each repo */
                        $repos = getAllRepos($mysqli_stats);

                        $selected = true;
                        $option = '';
                        foreach ($repos as $repo)
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
          <label for="package" class="control-label">Group</label>
              <div class="controls">
                <select id="package" name="package" class="input-xlarge">
                    <?php
                        /*
                         * Options will be:
                         * - Month
                         * - Day
                         * - Commit (None)
                         */
			$packages = getPackages($mysqli_stats);

			
                        echo '<option selected="selected">' . $packages['packages'][0] . '</option>';
                        echo '<option>' . $DAY . '</option>';
                        echo '<option>' . $COMMIT . '</option>';
                        
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
