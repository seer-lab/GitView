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

class Merger
    attr_accessor :test, :bad_files, :files_not_found

    def initialize(test)
        @test = test
        @bad_files = Array.new
        @files_not_found = 0
    end

    def mergePatch(lines, patch)

        if patch != nil && !lines[0][0].match(/^\d\d\d.*?/)

            # A file that does not have a new line at the end will have
            # '\ No newline at end of file' at the very end

            if @test
                puts "#{patch}"
            end

            patch = patch.gsub(NEWLINE_FIXER,"\n")

            patches = patch.scan(PATCH_EXPR)

            #patch = patch.gsub(NEWLINE_FIXER,"\n")
            #patchlines = patch.scan(LINE_EXPR)


            currentLine = 0

            deletions = 0
            #begin
            a = ''
        
            patches.each { |patchLine|
                #begin
                
                    if @test
                        puts "#{patchLine}"
                        #puts "patchDiff #{patchlines}"

                        puts "currentLine = #{currentLine}"
                        puts "line #{lines[currentLine]}"

                        #if lines[currentLine].class == Array
                        #    puts "line #{lines[currentLine][0]}"
                        #else
                            
                        #end
                    end

                    if patchLine[0] == "+"
                        #Addition
                        #puts "addition"
                        #line should be in file
                        lines[currentLine][0] =  "+" +  lines[currentLine][0]
                        currentLine+=1
                    elsif patchLine[0] == "-"
                        #Deletion
                        #puts "deletion"
                        #line should not be in the file.
                        lines.insert(currentLine, ["-" + patchLine[2]])
                        deletions += 1
                        currentLine+=1
                    elsif patchLine[0] == "@@"
                        #Patch start
                        #puts "patch start"
                        patchOffset = patchLine[2].scan(PATCH_LINE_NUM)

                        check = patchLine[2].scan(PATCH_LINE_NUM_OLD)
                    
                        if @test
                            if check[0] == nil
                                #Handle bad patch
                                puts "check #{check}"
                                #a = gets
                            end
                        end
                        #puts "patchoffset #{patchOffset}"
                        #puts "lines #{lines}"
                        lines, currentLine = fillBefore(lines, patchOffset[0][3].to_i-1 + deletions, currentLine)
                        deletions = 0
                    else
                        if patchLine[0] == nil && patchLine[2] == "\\ No newline at end of file" 
                        
                        elsif patchLine[0] == nil && patchLine[2] == ""

                        else 
                            #Context
                            #puts "context"
                            #Do nothing since the lines of code should alreay be there.
                            currentLine+=1
                        end
                    end

                    if @test
                        #puts lines[currentLine-1][0]
                        #a = gets

                        #puts lines[0]
                        #puts "deletions #{deletions}"
                        puts ""
                    end
            }
        elsif patch == nil
            if @test
                # Patch is empty
                puts "nothing in patch!?"
                # TODO ignore files without changes
            end
            lines.each do |line|
                line[0] = " #{line[0]}"
            end
        else             
            @files_not_found += 1
            @bad_files.push([lines, patch])
            if @test
                puts "File request error"
                puts "This has happened #{@files_not_found}"

                puts patch != nil
                puts !lines[0][0].match(/^\d\d\d.*?/)
                puts lines[0][0].scan(/^\d\d\d(.+)/)
                a = $stdin.gets
            end
        end
        
        return lines
    end

=begin
    puts "Bad files count #{@files_not_found}"
    puts ""

    bad_files.each { |info|

        info.each { |elements|
            a = $stdin.gets 
            puts elements
            puts ""
        }
        
    }
=end

    # TODO document
    def fillBefore (lines, offset, currentLine)

        while offset > currentLine do
            # Start setting the lines to empty
            lines[currentLine][0] = " " + lines[currentLine][0]
            currentLine+=1
        end

        return lines, currentLine
    end

end