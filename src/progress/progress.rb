
class Progress
    attr_accessor :orig_std, :total_length, :count

    BAR_LENGTH = 78
    OFFSET = 2

    def initialize(title=nil)
        @orig_std = $stdout.clone
        @total_length = 0
        @count = 0
        @app_title = title
    end

    def percentComplete(list=nil)
        cur_percent = (@count.to_f/@total_length)*100

        # Print clear character since system "clear" does not work from bash script
        @orig_std.print "\033c"

        if @app_title
            @orig_std.puts @app_title
        end

        if list
            list.each do |item|
                @orig_std.puts item
            end
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

        # Force the next print line to be on a new line
        @orig_std.print "\n"

        @count += 1
    end

    def puts(value)

        if value.class.name == Array.to_s
            
            values.each do |val|
                @orig_std.puts value
            end

        else
            @orig_std.puts value
        end
       
    end

ensure

    # Close the output stream
    if @orig_std
        @orig_std.close
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