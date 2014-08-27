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
require_relative 'database/tats_db_interface'

$high_threshold, $ONE_TO_MANY = 0.5, true
$low_threshold, $size_threshold = 0.8, 20
$test = true

def mergeThreshold(threshold)
    threshold = ((threshold.to_f*10).to_i).to_s
    if threshold.length == 1 
        threshold = "0#{threshold}"
    end
    return threshold
end

def getOutTags(con, repo_id)
    pick = con.prepare("SELECT t.tag_id FROM tags AS t, (SELECT c.commit_date AS last_date, r.repo_id AS r_repo FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference WHERE r.repo_id = ? ORDER BY c.commit_date DESC LIMIT 1) AS top WHERE t.repo_reference = top.r_repo AND t.tag_date > top.last_date")
    pick.execute(repo_id)

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end

def deleteTags(con, tag_id)
    pick = con.prepare("DELETE FROM tags WHERE tag_id = ?")
    pick.execute(tag_id)

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end

#con = Github_database.createConnection()

stats_con = Stats_db.createConnectionThreshold("#{$size_threshold.to_s}_#{mergeThreshold($low_threshold)}_#{mergeThreshold($high_threshold)}", $ONE_TO_MANY)

#repo = 0
repo = Stats_db.getRepos(stats_con)

#puts "repo #{repo}"

repo.each { |repo_id, repo_name, repo_owner|


	tags_ids = getOutTags(stats_con, repo_id)
    #puts "tags_ids = #{tags_ids}"

	tags_ids.each { |tag_id|
	    if !$test
	        deleteTags(stats_con, tag_id[0])
	    else
	        puts "tag_id = #{tag_id[0]}"
	    end
	}
}