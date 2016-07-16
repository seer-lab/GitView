
filename = ARGV[0]
    
fixed_lines = Array.new
File.foreach(filename) do |line|

    values = line.split(/,/)

    result = values[-1].gsub(/\[|\]/, '').scan(/\s*([0-9\.]+)\s*/).map do |x|
        x[0].to_f
    end

    fixed_lines << "#{values[0]}, #{result.join(', ')}"	

end

File.open(filename, 'w') do |f|

    fixed_lines.each do |line|
        f.puts line
    end
end
