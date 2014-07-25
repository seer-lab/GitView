require_relative 'stats_db_interface'

HIGH_THRESHOLD=0.5
LOW_THRESHOLD=0.8
SIZE_THRESHOLD=20
MUL=true

class InfoCollector
	#attr_accessor :output_dir, :percent_name, :comment_name, :extension
	FILE_MODE = "w"
	EXTENSION = "csv"

	def initialize(output_dir, percent_name, comment_name, extension=EXTENSION)
		#@output_dir = output_dir
		#@percent_name = percent_name
		#@comment_name = comment_name
		#@extension = extension

		@file_percentages_stdout = $stdout.clone

		@comment_stdout = $stdout.clone

		if !Dir.exist?(output_dir)
			Dir.mkdir(output_dir)
		end

		@file_percentages_stdout.reopen("#{output_dir}/#{percent_name}.#{extension}", FILE_MODE)
		@comment_stdout.reopen("#{output_dir}/#{comment_name}.#{extension}", FILE_MODE)
	end

	def output_stats_info(stats_conn)

		repos = Stats_db.getRepos(stats_conn)

		

		index = 0
		repos.each do |repo_id, repo_name, repo_owner|

			# Output the repo's name
			@file_percentages_stdout.puts "#{repo_owner}/#{repo_name}"
			@comment_stdout.puts "#{repo_owner}/#{repo_name}"

			# Output the heading
			@file_percentages_stdout.puts "path, file name, percent"
			@comment_stdout.puts "commit id, message"

			percentages = Stats_db.getFileCommitPercent(stats_conn, repo_owner, repo_name)

			percentages.each do |path, file_name, percent|

				@file_percentages_stdout.puts "#{path}, #{file_name}, #{percent}"
			end

			messages = Stats_db.getCommitMessages(stats_conn, repo_owner, repo_name)

			messages.each do |commit_id, message|
				@comment_stdout.puts "#{commit_id}, #{message}"
			end

			index += 1

			if index < repos.length
				@file_percentages_stdout.puts ""
				@comment_stdout.puts ""
			end
		end
	end
ensure

	# Close percentage output
	if @file_percentages_stdout
		@file_percentages_stdout.close
	end

	# Close comment output
	if @comment_stdout
		@comment_stdout.close
	end
end

stats_conn = Stats_db.createConnectionThreshold("#{SIZE_THRESHOLD}_#{Stats_db.mergeThreshold(LOW_THRESHOLD)}_#{Stats_db.mergeThreshold(HIGH_THRESHOLD)}", MUL)

output_dir = "stats_output"
precentage = "file_percentages"
comment = "comment_output"

ic = InfoCollector.new(output_dir, precentage, comment)
ic.output_stats_info(stats_conn)