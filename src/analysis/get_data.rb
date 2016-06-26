require 'json'
require_relative '../database/pg-interface'
require_relative 'bidirectional_map'

ALPHABET_SIZE = 26
LETTER_OFFSET= 97

class String
    def is_i?
       /\A[-+]?\d+\z/ === self
    end
end

def string_to_array(text)
    #text.strip.gsub(/[\{\}]/, '').split(/,/).map {|x| x.strip }
    values = text.gsub(/[\(\)\"]/, '').scan(/\{(.+?)\}/)
    
    if values && !values.empty?
        values = values.map do |entry|
            entry[0].split(/,/).map do |val|
                val.strip
            end
        end
    else
        values = [[], []]
    end
    return values
end

def split_change(change_type)
    list = [-1, -1, -1, -1]
    if change_type == 0
        list[0] = 1
    elsif change_type == 1
        list[1] = 1
    elsif change_type == 2
        list[2] = 1
    elsif change_type == 3
        list[3] = 1
    end
    return list
end

def count_letters(text)
    letters = text.gsub(/[^[:alpha:]]/, '').downcase

    counts = Array.new

    ALPHABET_SIZE.times do |index|
        counts << letters.count((index+LETTER_OFFSET).chr)
    end

    return counts
end

def get_data_files(rows, mappers=nil, categories=nil)

    mapper_count = 0
    skip = false

    method_id_index = 2

    prev_types_count = 0
    

    method_info_id_mapper = BidirectionalMap.new

    if categories == nil
        categories = Array.new
    end

    header = rows.first.keys

    puts "rowsize = #{rows.size}"

    data = Array.new
    rows.each do |row|
        data << Array.new

        index = 0
        row.each do |key, val|

            #val = col.strip
            # Second last index
            if key == "previous_change_type"
                # Convert the array to elements and ensure it has the correct number values
                prev_changes = string_to_array(val)

                prev_changes.each_with_index do |changes, index|

                    while changes.size < PREV_TYPES_MAX
                        # -1 is assigned if no change is present. TODO maybe throw an error (aka require at least 5 previous changes be made).
                        if index == 0
                            changes << 0
                        else
                            changes << -1
                        end
                    end

                    # Add the elements to the list
                    changes.each do |ary_ele|
                        if index == 0
                            # Not using changes
                            #data[-1] += split_change(ary_ele.to_i)
                            #data[-1] << (ary_ele.to_i > 0 ? 1 : 0)
                        else
                            data[-1] << ary_ele.to_i
                        end
                        break
                    end
                end
            else

                if val == nil
                    puts "key #{key}"
                end

                #puts "val = #{val}"
                # Map the string if needed.
                if !val.is_i? && key != 'short_change_freq' && key != 'change_frequency'
                    #if key == 'signature'
                        # Bucket the methods names into counts.
                    #    data[-1] += count_letters(val)
                    #    skip = true
                   # else

                        # Only create the a mapper if it is needed
                        if mapper_count > mappers.size - 1 && !mappers.has_key?(key)
                            mappers[key] = BidirectionalMap.new
                        end

                        val = mappers[key][val]
                        mapper_count += 1
                    #end
                else
                    

                    val = val.to_f
                    if key == 'method_info_id'
                        method_info_id_mapper[val]
                        skip = true
                    end
                end
                    
                if !skip
                    data[-1] << val
                end
                skip = false
            end
                index += 1
        end
        mapper_count = 0

        # Take the final column from the row and use it as the category
        categories << data[-1].delete_at(-1)
    end


    #header = data.delete_at(0)

    #category_header = categories.delete_at(0)

    header.delete_at(method_id_index)
    return {:data => data, :mapper => mappers, :categories => categories, :header => header}
end

repo_owner = nil
repo_name = nil
limit = 1.0
repos = nil
group = nil
feature_set = 1
use_os = false

if ARGV.size >= 4 || ARGV.size <= 8
    repos = [{:repo_owner => ARGV[0], :repo_name => ARGV[1]}]
    limit = ARGV[2].to_f
    
    commit_width = ARGV[3]
    test_commit_width = commit_width
    test_offset = nil
    

    if ARGV.size >= 5
        feature_set = ARGV[4].to_i
    end

    if ARGV.size >= 6
        use_os = ARGV[5].to_i == 1
    end

    if ARGV.size == 7
        test_offset = ARGV[6].to_i
    end

    if ARGV.size == 8
        test_commit_width = ARGV[6].to_i
        test_offset = ARGV[7].to_i
    end


    # 1 <= quarter <=4
    #if end_quarter < 1 || end_quarter > 4
    #    Kernel.exit 1
    #end
elsif ARGV.size == 2
    group = true
    commit_width = ARGV[0]
    test_commit_width = commit_width
    test_offset_o = ARGV[1].to_i
    test_offset = test_offset_o
else
    Kernel.exit 1 
end

PREV_TYPES_MAX = 5

db = DBinterface.new('project_stats')

train_data = nil
test_data = nil
if repos == nil
    repos = Array.new
    repo_owner = ['ACRA', 'square', 'facebook', 'deeplearningj4']# , 'apache'
    repo_name = ['acra', 'dagger', 'fresco', 'deeplearningj4'] #'storm',
    repo_owner.each_with_index do |owner, index|
        repos << {:repo_owner => owner, :repo_name => repo_name[index]}
    end
    train_entries = Hash.new
    test_entries = Hash.new
    train_data = {:data => [], :categories => []}
    test_data = {:data => [], :categories => []}
end

puts "repos = #{repos}"
puts "limit = #{limit}"
puts "commit_width = #{commit_width}"
puts "test_commit_width = #{test_commit_width}"
puts "test_offset = #{test_offset}"

#mappers = Hash.new

#categories = Array.new

repos.each do |repo|

    puts "repo[:repo_owner] = #{repo[:repo_owner]}, repo[:repo_name] = #{repo[:repo_name]}, commit_width = #{commit_width}, test_commit_width = #{test_commit_width}, test_offset = #{test_offset}"
    date_range = db.get_date_range(repo[:repo_owner], repo[:repo_name], commit_width, test_commit_width, test_offset)

    #puts "Date offset = #{date_range}"

    #puts "Start = #{start_quarter}, #{date_range[0]["quarter_#{start_quarter}"]}"
    #puts "End = #{date_range[0]["quarter_#{end_quarter}"]}"

    date_range.each_with_index do |range, index|

        if range == nil
            Kernel.exit 1
        end

        if test_offset == nil
            test_offset = index
        else
            mappers = Hash.new

            categories = Array.new
        end 
        raw_data = db.get_svm_data(repo[:repo_owner], repo[:repo_name], range['start'], range['buffer'], limit, commit_width, range['min'], feature_set, use_os, false)

        file_info = get_data_files(raw_data, mappers, categories)

        if group#repos.size > 1
            #train_entries[repo[:repo_name]] = file_info
            train_data[:data] += file_info[:data]
            # Example =
            puts "Example = #{train_data[:data].last}"
            train_data[:categories] += file_info[:categories]
            puts "Size of data = #{train_data[:data].size}"
            puts "Size of categories = #{train_data[:categories].size}"
        else
            puts "Example = #{file_info[:data].last}"
        end

        puts "data saved in data/train_data_sample_#{repo[:repo_owner]}_#{repo[:repo_name]}_#{limit}_#{commit_width}_#{test_commit_width}_#{test_offset}"
        # Put the data into a file.
        File.open("data/train_data_sample_#{repo[:repo_owner]}_#{repo[:repo_name]}_#{limit}_#{commit_width}_#{test_commit_width}_#{test_offset}", "w") do |f|
            f.print file_info.to_json
        end

        categories.clear

        if repos.size == 1 || (repo[:repo_name] == 'acra' || repo[:repo_name] == "dagger")
            raw_data = db.get_svm_data(repo[:repo_owner], repo[:repo_name], range['current'], range['end'], limit, commit_width, range['min'], feature_set, use_os)

            file_info = get_data_files(raw_data, mappers, categories)

            if group#repos.size > 1
                #test_entries[repo[:repo_name]] = file_info
                test_data[:data] += file_info[:data]
                puts "Test Example = #{file_info[:data].last}"
                test_data[:categories] += file_info[:categories]
                puts "Size of data = #{test_data[:data].size}"
                puts "Size of categories = #{test_data[:categories].size}"
                puts "Size of file_info data = #{file_info[:data].size}"
                puts "Size of file_info categories = #{file_info[:categories].size}"
            else
                puts "Test Example = #{file_info[:data].last}"
            end

            puts "data saved in data/test_data_sample_#{repo[:repo_owner]}_#{repo[:repo_name]}_#{limit}_#{commit_width}_#{test_commit_width}_#{test_offset}"
            # Put the data into a file.
            File.open("data/test_data_sample_#{repo[:repo_owner]}_#{repo[:repo_name]}_#{limit}_#{commit_width}_#{test_commit_width}_#{test_offset}", "w") do |f|
                f.print file_info.to_json
                end
        end
    end

    #test_offset = test_offset_o
end

# Aggregate the test files
if group#repos.size > 1
    #train_data = {:data => [], :categories => []}

    #train_entries.each do |key, entry|
    #    train_data[:data] += entry[:data]
    #    train_data[:categories] += entry[:categories]
    #end

    puts "Size of data = #{train_data[:data].size}"
    puts "Size of categories = #{train_data[:categories].size}"

    File.open("data/train_data_sample_group_1.0_#{commit_width}_#{test_commit_width}_#{test_offset}", "w") do |f|
        f.print train_data.to_json
    end

    #test_data = {:data => [], :categories => []}
    #test_entries.each do |key, entry|
    #    test_data[:data] += entry[:data]
    #    test_data[:categories] += entry[:categories]
    #end

    puts "Size of data = #{test_data[:data].size}"
    puts "Size of categories = #{test_data[:categories].size}"

    File.open("data/test_data_sample_group_1.0_#{commit_width}_#{test_commit_width}_#{test_offset}", "w") do |f|
        f.print test_data.to_json
    end
end