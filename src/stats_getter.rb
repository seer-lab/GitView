require_relative 'stats_db_interface'

$threshold = 0.5

$threshold = gets.chomp!

con = Stats_db.createConnection($threshold)

PATH = "../parse_log/stats_#{$threshold}/"
Dir.mkdir(PATH) unless File.exists?(PATH)

repos = Stats_db.getRepos(con)

repos.each { |repo|

	total_comment_addition = 0
	total_comment_deletion = 0
	total_comment_modified = 0
	total_code_addition = 0
	total_code_deletion = 0
	total_code_modified = 0
	fileName = "stats_#{repo[0]}_#{repo[1]}_#{$threshold}"

	$stdout.reopen("#{PATH}#{fileName}", "w")
	stats = Stats_db.getCommitStats(con, repo[1], repo[0])

	stats.each { |stat|
		puts "#{stat[0]}, #{stat[1]}, #{stat[2]}, #{stat[3]}, #{stat[4]}, #{stat[5]}, #{stat[6]}"

		total_comment_addition += stat[1]
		total_comment_deletion += stat[2]
		total_comment_modified += stat[3]
		total_code_addition += stat[4]
		total_code_deletion += stat[5]
		total_code_modified += stat[6]
	}
	puts "total_comment_addition = #{total_comment_addition}"
	puts "total_comment_deletion = #{total_comment_deletion}"
	puts "total_comment_modified = #{total_comment_modified}"
	puts "total_code_addition = #{total_code_addition}"
	puts "total_code_deletion = #{total_code_deletion}"
	puts "total_code_modified = #{total_code_modified}"
}

