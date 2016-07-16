

#      | Best               | Worst               |
# name | fs      | swr      | fs       | swr      |
# name & best fs & best swr & worst fs & worst swr


require 'json'

method = 'svm'
results = ['best', 'worst']

FILE_INPUT="weight_sum"

data = Hash.new

results.each do |result|
	File.open("#{FILE_INPUT}/#{result}_#{method}", 'r') do |file|
	    data[result] = JSON.parse(file.gets.chomp)
	end

	data[result] = data[result].sort_by do |v|
		v[0].downcase
	end
end

data[results[0]].each_with_index do |best, index|
	
	puts "#{best[0]} & #{best[2]} & #{best[3]} & #{data[results[1]][index][2]} & #{data[results[1]][index][3]} \\\\"
end