
class Progress
    attr_accessor :orig_std, :total_length, :count

    def initialize
        @orig_std = $stdout.clone
        @total_length = 0
        @count = 0
    end

    def percentComplete(name)
        cur_percent = (@count.to_f/@total_length)*100

        # Print clear character since system "clear" does not work from bash script
        @orig_std.puts "\033c"

        @orig_std.puts "Working on Files..."
        if name
            @orig_std.puts "Current File: #{name}"
        end
        @orig_std.puts "Percent Complete #{format("%.1f",cur_percent)}%"
        @count += 1
    end

    def puts(value)
        @orig_std.puts value
    end
end

=begin
pi = Progress.new

$stdout.reopen("temp", "a")

pi.total_length = 100

pi.puts("HERE")
pi.percentComplete("NAME")
puts "HERE"
=end