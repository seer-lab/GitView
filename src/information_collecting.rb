require_relative 'stats_db_interface'

def mergeThreshold(threshold)
    threshold = ((threshold.to_f*10).to_i).to_s
    if threshold.length == 1 
        threshold = "0#{threshold}"
    end
    return threshold
end

stats_conn = Stats_db.createConnectionThreshold("#{20}_#{mergeThreshold(0.8)}_#{mergeThreshold(0.5)}", true)

repos = Stats_db.getRepos(stats_conn)

file_percentages_stdout = $stdout.clone

comment_stdout = $stdout.clone

file_percentages_stdout.reopen("../stats_output/file_percentages", "a")
comment_stdout.reopen("../stats_output/comment_output", "a")

file_percentages_stdout.puts "path, file name, percent"
comment_stdout.puts "commit id, message"

index = 0
repos.each do |repo_id, repo_name, repo_owner|

	file_percentages_stdout.puts "#{repo_owner}/#{repo_name}"
	comment_stdout.puts "#{repo_owner}/#{repo_name}"

	percentages = Stats_db.getFileCommitPercent(stats_conn, repo_owner, repo_name)

	percentages.each do |path, file_name, percent|

		file_percentages_stdout.puts "#{path}, #{file_name}, #{percent}"
	end

	messages = Stats_db.getCommitMessages(stats_conn, repo_owner, repo_name)

	messages.each do |commit_id, message|
		comment_stdout.puts "#{commit_id}, #{message}"
	end

	index += 1

	if index < repos.length
		file_percentages_stdout.puts ""
		comment_stdout.puts ""
	end
end

#$stdout.reopen("../stats_output/messages", "a")