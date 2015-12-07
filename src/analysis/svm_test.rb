require 'libsvm'
require 'colorize'
require 'json'
require_relative '../database/pg-interface'
require_relative 'bidirectional_map'

repo_owner = 'ACRA'
repo_name = 'acra'
limit = 100
end_quarter = 1
start_quarter = end_quarter - 1

if ARGV.size == 4 || ARGV.size == 5
    repo_owner = ARGV[0]
    repo_name = ARGV[1]
    limit = ARGV[2].to_i
    end_quarter = ARGV[3].to_i
    start_quarter -= 1

    if ARGV.size == 5
        start_quarter = end_quarter
        end_quarter = ARGV[4].to_i
    end

else
    Kernel.exit 1 
end

data = Array.new

mappers = Hash.new

categories = Array.new

#PREV_TYPES_MAX = 5
File.open("data/test_sample_#{repo_owner}_#{repo_name}_#{limit}_#{start_quarter}_#{end_quarter}_desc", "r") do |f|
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

# This library is namespaced.
problem = Libsvm::Problem.new
parameter = Libsvm::SvmParameter.new

parameter.cache_size = 1 # in megabytes

parameter.eps = 0.001
parameter.c = 10

#puts "data = #{data}"

# Print the data out to a file to allow for use with easy.py
File.open("data/train_data_#{repo_owner}_#{repo_name}_#{limit}_q#{start_quarter}_q#{end_quarter}_desc", "w") do |f|
    data.each_with_index do |row, index|
        f.print "#{categories[index]}"
        row.each_with_index do |col, i|
            f.print " #{i+1}:#{col}"
        end
        f.puts  
    end
end

puts "mapping"
examples = data.map {|ary| Libsvm::Node.features(ary) }

puts "Training"
problem.set_examples(categories, examples)

model = Libsvm::Model.train(problem, parameter)

#try = [1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]

puts "Setting up test"
#2984
# TODO get a few examples from the data set (not already in use in the training set) to try.
# TODO make sure the only 8 values are passed to the model
#try =#["107", "acra/src/main/java/org/acra/util/", "Base64.java", "public static byte[] decode(String str, int flags) {", "1", "pyricau", "pyricau", "2"]
#try = ["79", "CrashReport/src/org/acra/", "ErrorReporter.java", "public static ErrorReporter getInstance() {", "0", "KevinGaudin", "KevinGaudin", "7"]

examples = Array.new
classification = Array.new

File.open("data/test_sample_#{repo_owner}_#{repo_name}_#{limit}_#{start_quarter+end_quarter}_#{end_quarter+end_quarter}_desc", "r") do |f|
    json_data = f.gets
    raw_data = JSON.parse(json_data)

    examples = raw_data['data']
    classification = raw_data['categories']
end

#file_data = get_data_files("data/example_data_#{training_size}_q#{range+1}", mappers, Array.new)
#examples = file_data[:data]
#classification = file_data[:categories]

#puts "examples = #{examples}"

correct = 0
examples.each_with_index do |try, index|
    pred = model.predict(Libsvm::Node.features(try))
    
    if pred == classification[index]
        print "Success".green
        correct += 1
    else
        print "Failed".red
    end
    puts " - Predicted #{pred}, Actual #{classification[index]} - Example #{try}"
end

puts "Success Rate: #{correct}/#{examples.size} = #{correct.to_f/examples.size}"

#(-1..1).each do |f|
#    (-1..1).each do |s|
#        (-1..1).each do |t|
            
#        end
#    end
#end