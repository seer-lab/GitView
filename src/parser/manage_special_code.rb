###############################################################################
# Copyright (c) 2014 Jeremy S. Bradbury, Joseph Heron
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###############################################################################

class ManageSpecialCode
    attr_accessor :commentOpen

    def initialize
        @commentOpen = false
    end

    # Removes the quoted sections quotes for the line.
    def removeQuotes(line)
        length = line.scan(/"/).length
        if length < 2
            # Nothing change
            return line
        elsif length == 2
            return line.gsub(/".*"/,'')
        else
            # Best attempt, will still fail given:
            # "System.out.println(\"\\\"+ \"the sunny\\\" day\");"
            # Since the first one is block "\\" is picked up as not ending
            # This is because there is no difference between (as far as ruby is concerned) 
            # with "\\" and "\". The second would not compile in Java. However both would
            # be represented with \"\\\" in ruby (since ruby is forcing it to be a string)
            # The problem being that \" is used in Java and ruby to show an escaped quote
            # however ruby then takes that string and converts it to \\\" to indicate an
            # escaped quote and an escaped forward slash.
            inQuote = false
            escape_count = 0
            newLine = ''
            line.each_char do |c|
                #puts "c = #{c}"
                if inQuote
                    if c == '\\'
                        escape_count += 1
                    elsif c == '"'
                        if (escape_count+1) % 2 == 0
                            #puts "HERE"
                            escape_count = 0
                        else
                            inQuote = false
                        end
                    else
                        escape_count = 0
                    end
                else
                    if c == '"'

                        inQuote = true
                    else
                        newLine << c
                    end
                end
                #puts "inside = #{inQuote}"
            end
            return newLine
        end
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
mq = ManageSpecialCode.new
first_line = "System.out.println(\"reserve characters are: ; { class public \\n // /*\");"
second_line = "System.out.println(\"Cleaned ; /* comment? */"
third_line = "finished // everything \" + value);"

[first_line, second_line, third_line].each do |line|
    # Todo compare to expected
    puts mq.removeQuotes(line)
end
=end