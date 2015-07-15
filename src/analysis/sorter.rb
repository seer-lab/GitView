
offset = 11
type = :commit

sorted = File.open("grid_output_#{type.to_s}_sorted.txt", 'w')

lines = Array.new
File.open("grid_output_#{type.to_s}.txt", 'r') do |f|
    f.each_line do |line|
        lines << line
    end
end

# Sort by the range that states the commit (rather than the method identifier) and then reverse it so that we are looking at oldest to newest commit.
result = lines.sort_by {|line| line[offset..-1]}.reverse

result.each do |line|

    sorted << line
end

sorted.close