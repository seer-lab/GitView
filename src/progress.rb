
class Progress
    attr_accessor :orig_std, :total_length, :count

    BAR_LENGTH = 78
    OFFSET = 2

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

        @orig_std.print "|"

        (BAR_LENGTH-OFFSET).times do |v|
            if v <= ((BAR_LENGTH-OFFSET) * (cur_percent/100)).ceil
                @orig_std.print "#"
            else
                @orig_std.print " "
            end
        end

        @orig_std.print "|"

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