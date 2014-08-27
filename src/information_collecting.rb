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

require_relative 'database/stats_db_interface'

HIGH_THRESHOLD=0.5
LOW_THRESHOLD=0.8
SIZE_THRESHOLD=20
MUL=true

class InfoCollector
	#attr_accessor :output_dir, :percent_name, :comment_name, :extension
	FILE_MODE = "w"
	EXTENSION = "csv"
	DELIMITER = ', '

	def initialize(output_dir, percent_name, comment_name, file_metric, extension=EXTENSION)
		#@output_dir = output_dir
		#@percent_name = percent_name
		#@comment_name = comment_name
		#@extension = extension

		@file_percentages_stdout = $stdout.clone

		@comment_stdout = $stdout.clone
		@file_metrics_stdout = $stdout.clone

		if !Dir.exist?(output_dir)
			Dir.mkdir(output_dir)
		end

		@file_percentages_stdout.reopen("#{output_dir}/#{percent_name}.#{extension}", FILE_MODE)
		@comment_stdout.reopen("#{output_dir}/#{comment_name}.#{extension}", FILE_MODE)

		@file_metrics_stdout.reopen("#{output_dir}/#{file_metric}.#{extension}", FILE_MODE)
	end

	def output_stats_info(stats_conn)

		Stats_db.getRepos(stats_conn).each do |repo_id, repo_name, repo_owner|

			# Output the repo's name
			@file_percentages_stdout.puts create_csv_row([repo_owner, repo_name])
			@comment_stdout.puts create_csv_row([repo_owner, repo_name])

			# Output the heading
			#@file_percentages_stdout.puts "path, file name, percent, initial commit, final commit"
			#@comment_stdout.puts "commit id, message"
			first = true

			Stats_db.getFileCommitPercent(stats_conn, repo_owner, repo_name).each do |row|

				if first
					# Output the title line
					@file_percentages_stdout.puts create_csv_row(row.keys)
					first = false
				end

				# Output the data
				@file_percentages_stdout.puts create_csv_row(row.values)
			end

			first = true

			Stats_db.getCommitMessages(stats_conn, repo_owner, repo_name).each do |row|

				if first
					# Output the title line
					@comment_stdout.puts create_csv_row(row.keys)
					first = false
				end

				# Output the data
				@comment_stdout.puts create_csv_row(row.values)
			end

			@file_percentages_stdout.puts ""
			@comment_stdout.puts ""
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

	def outputMonthAverage(stats_conn)

		Stats_db.getAllRepoMonthAverage(stats_conn).each do |month_avg|

			# Print the title
			@file_metrics_stdout.puts create_csv_row(month_avg.keys.insert(2 ,""))

			# Print the data
			@file_metrics_stdout.puts create_csv_row(month_avg.values.insert(2, ""))

			first = true

			Stats_db.getImportantFilesByMethod(stats_conn, month_avg['repo_owner'], month_avg['repo_name'], month_avg[Stats_db::AVERAGE_METHODS_ADDED], month_avg[Stats_db::AVERAGE_DELETED_METHODS], month_avg[Stats_db::AVERAGE_METHODS_MODIFIED]).each do |row|


				if first
					# Output the title line
					@file_metrics_stdout.puts create_csv_row(row.keys)
					first = false
				end

				# Print the data
				@file_metrics_stdout.puts create_csv_row(row.values)
			end

			@file_metrics_stdout.puts ""
		end

		@file_metrics_stdout.close
	end

	def create_csv_row(row)

		output = ""

		if row.class.name == Array.to_s
			row.each do |element|
				output += "#{element}#{DELIMITER}"	
			end
		else
			return nil
		end

		# Remove trailing delimiter
		output[0..-(1+DELIMITER.length)]
	end

end

stats_conn = Stats_db.createConnectionThreshold("#{SIZE_THRESHOLD}_#{Stats_db.mergeThreshold(LOW_THRESHOLD)}_#{Stats_db.mergeThreshold(HIGH_THRESHOLD)}", MUL)

output_dir = "stats_output"
precentage = "file_percentages"
comment = "comment_output"
file_metric = "file_metrics"

ic = InfoCollector.new(output_dir, precentage, comment, file_metric)
ic.output_stats_info(stats_conn)
ic.outputMonthAverage(stats_conn)