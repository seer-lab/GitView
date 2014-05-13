
class ManageQuotes
    attr_accessor :commentOpen

    def initialize
        @commentOpen = false
    end

    # Removes the quoted sections quotes for the line.
    def removeQuotes(line)
        return line.gsub(/".*"/,'')
    end

    # Remove the single line comment
    def removeSingleLineComment(line)
        return line.gsub(/(\/\/.*$)|(\/\*.*\*\/)/,'')
    end

    def removeMultComment(line)

        # Check if the line is in the middle of a comment
        if @commentOpen
            # check if closing
            if line.match(/.*\*\//)
                # Comment finished
                @commentOpen = false

                # Remove Comment
                line.gsub!(/.*\*\//, '')
            else
                # In the middle of a comment, clear the line
                line = ''
            end
        else
            # Check if a new comment block is starting
            if line.match(/\/\*.*$/)
                @commentOpen = true

                # Remove the comment on the line
                line.gsub!(/\/\*.*$/, '')
            end
        end
        return line
    end

    def removeComments(line)
        line = removeSingleLineComment(line)
        return removeMultComment(line)
    end

    # Call all cleaning methods
    def cleanLine(line)
        line = removeQuotes(line)
        line = removeSingleLineComment(line)
        return removeMultComment(line)
    end
end


# TODO move to test case
=begin
mq = ManageQuotes.new
first_line = "System.out.println(\"reserve characters are: ; { class public \\n // /*\");"
second_line = "System.out.println(\"Cleaned ; /* comment? */"
third_line = "finished // everything \" + value);"

[first_line, second_line, third_line].each do |line|
    # Todo compare to expected
    puts mq.removeQuotes(line)
end
=end