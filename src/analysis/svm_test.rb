
require 'colorize'
require 'json'
require_relative '../database/pg-interface'
require_relative 'bidirectional_map'

require_relative 'predictors'

repo_owner = 'ACRA'
repo_name = 'acra'
limit = 100

if ARGV.size == 5 || ARGV.size == 6 || ARGV.size == 7
    repo_owner = ARGV[0]
    repo_name = ARGV[1]
    limit = ARGV[2].to_f

    commit_width = ARGV[3].to_i
    test_commit_width = commit_width
    test_offset = nil

    performance_file = ARGV[4]

    if ARGV.size == 6
        test_offset = ARGV[5].to_i
    end

    if ARGV.size == 7
        test_commit_width = ARGV[5].to_i
        test_offset = ARGV[6].to_i
    end

else
    Kernel.exit 1 
end

data = Array.new

mappers = Hash.new

categories = Array.new

puts "FILE = data/train_data_sample_#{repo_owner}_#{repo_name}_#{limit}_#{commit_width}_#{test_commit_width}_#{test_offset}"
#PREV_TYPES_MAX = 5
File.open("data/train_data_sample_#{repo_owner}_#{repo_name}_#{limit}_#{commit_width}_#{test_commit_width}_#{test_offset}", "r") do |f|
    json_data = f.gets
    raw_data = JSON.parse(json_data)

    data = raw_data['data']
    mapper = raw_data['mapper']
    categories = raw_data['categories']
end

#TRAINING_SIZE = 100

# method_info_id is at index 3 so we need to remove it from the dataset and keep it as a reference

#TODO randomize the rows that are retrieved for the training set.

# Remove the first row since it is just the header

#predictor = FANN_Predictor.new(data.first.size)
predictor = SVM_Predictor.new(2.0, 8.0)

puts "data = #{data.size}"

# Print the data out to a file to allow for use with easy.py
File.open("data/train_data_#{repo_owner}_#{repo_name}_#{limit}_#{commit_width}_#{test_commit_width}_#{test_offset}", "w") do |f|
    data.each_with_index do |row, index|
        f.print "#{categories[index]}"
        row.each_with_index do |col, i|
            f.print " #{i+1}:#{col}"
        end
        f.puts  
    end
end


puts "Training"
predictor.train(data, categories)


puts "Setting up test"

examples = Array.new
classification = Array.new


#/0.2
File.open("data/test_data_sample_#{repo_owner}_#{repo_name}_#{limit}_#{commit_width}_#{test_commit_width}_#{test_offset}", "r") do |f|
    json_data = f.gets
    raw_data = JSON.parse(json_data)

    examples = raw_data['data']
    classification = raw_data['categories']
end


#puts "examples = #{examples}"

# Print out the test_data into a file to use with libsvm.
File.open("data/test_data_#{repo_owner}_#{repo_name}_#{limit}_#{commit_width}_#{test_commit_width}_#{test_offset}", "w") do |f|
    examples.each_with_index do |row, index|
        
        f.print "#{classification[index]}"
        row.each_with_index do |col, i|
            f.print " #{i+1}:#{col}"
        end
        f.puts  
    end
end

#Kernel.exit 0

true_positive = 0
true_negative = 0
false_positive = 0
false_negative = 0

correct = 0
examples.each_with_index do |try, index|
    pred = predictor.test(try)
    
    if pred.round == classification[index]
        print "Success".green
        correct += 1

        if pred.round == 1
            true_positive += 1
        else
            true_negative += 1
        end
    else
        print "Failed".red

        if pred.round == 1
            false_positive += 1
        else
            false_negative += 1
        end
    end
    puts " - Predicted #{pred}, Actual #{classification[index]} - Example #{try}"
end

accuracy = correct.to_f/examples.size
precision = true_positive / (true_positive + false_positive).to_f
recall = true_positive / (true_positive + false_negative).to_f

puts "Success Rate: #{correct}/#{examples.size} = #{accuracy}"
puts "Precision = #{precision}"
puts "Recall = #{recall}"

File.open(performance_file, 'a') do |f|
    f.puts "#{precision}, #{recall}, #{accuracy}"
end

#(-1..1).each do |f|
#    (-1..1).each do |s|
#        (-1..1).each do |t|
            
#        end
#    end
#end