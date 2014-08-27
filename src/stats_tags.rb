###############################################################################
# Copyright (c) 2014 Jeremy S. Bradbury, Joseph Heron
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###############################################################################

require_relative 'database/database_interface'
require_relative 'regex'
require_relative 'database/stats_db_interface'

$high_threshold, $ONE_TO_MANY = 0.5, true
$low_threshold, $size_threshold = 0.8, 20
$test = false

def mergeThreshold(threshold)
    threshold = ((threshold.to_f*10).to_i).to_s
    if threshold.length == 1 
        threshold = "0#{threshold}"
    end
    return threshold
end


con = Github_database.createConnection()

stats_con = Stats_db.createConnectionThreshold("#{$size_threshold.to_s}_#{mergeThreshold($low_threshold)}_#{mergeThreshold($high_threshold)}", $ONE_TO_MANY)

repo = 0

repo = Stats_db.getRepos(stats_con)

repo.each { |repo_id, repo_name, repo_owner|

	tags = Github_database.getTags(con, repo_name, repo_owner)

	tags.each { |sha, tag_name, tag_desc, tag_date|
	    if !$test
	        Stats_db.insertTag(stats_con, repo_id, sha, tag_name, tag_desc, tag_date)
	    else
	        puts "sha = #{sha}"
	        puts "tag_name = #{tag_name}"
	        puts "tag_desc = #{tag_desc}"
	        puts "tag_date = #{tag_date}"
	    end
	}
}