require_relative 'database_interface'
require_relative 'regex'
require_relative 'stats_db_interface'

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