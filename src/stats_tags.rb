require_relative 'database_interface'
require_relative 'regex'
require_relative 'stats_db_interface'

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