
class ManageQuotes
    attr_accessor :prevOpen

    def initialize
        @prevOpen = false
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

    # Call all cleaning methods
    def cleanLine(line)
        line = removeQuotes(line)
        return removeSingleLineComment(line)
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