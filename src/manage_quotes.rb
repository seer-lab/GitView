
class ManageQuotes
    attr_accessor :prevOpen, :commentOpen

    def initialize
        @prevOpen = false
        @commentOpen = false
    end

    # Determines if a quote needs to be added at the beginning or at the end of the line
    def checkQuote(line)
        numComments = line.scan(/[^\\]"/).length
        #Special case when it is just two quotes side by side
        specialCase = line.scan(/[^\\]""/).length
        numComments += specialCase
        beginning = false
        ending = false

        if numComments % 2 == 0 && !@prevOpen
            # Quote not open
        elsif numComments % 2 == 0 && @prevOpen
            beginning = true
            ending = true
        elsif numComments % 2 == 1 && !@prevOpen
            #Quote is now open
            ending = true
        elsif numComments % 2 == 1 && @prevOpen
            #Quote is now closed
            beginning = true
            @prevOpen = false
        end

        return beginning, ending
    end

    # Removes the quoted sections quotes for the line 
    def stripLine(line, beginning, ending)
        if beginning
            line = "\"#{line}"
        end
        if ending
            line = "#{line}\""
        end
        return line.gsub(/"([^"]*)"/,'')
    end

    # Facilitates the removal of the quoted text.
    def removeQuotes(line)
        beginning, ending = checkQuote(line)
        newLine = stripLine(line, beginning, ending)

        @prevOpen = ending
        return newLine
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