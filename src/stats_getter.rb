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

$threshold = 0.5
$multi = false
puts "threshold"
$threshold = gets.chomp!
puts "mulit"
$multi = gets.chomp!

con = Stats_db.createConnection($threshold, $multi)

PATH = "../parse_log/stats_#{$threshold}_M#{$multi}/"
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

