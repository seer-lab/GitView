
class Merger
    attr_accessor :test

    def initialize(test)
        @test = test
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
            $NOT_FOUND += 1
            $BAD_FILE_ARRAY.push([lines, patch])
            if @test
                puts "File request error"
                puts "This has happened #{$NOT_FOUND}"

                puts patch != nil
                puts !lines[0][0].match(/^\d\d\d.*?/)
                puts lines[0][0].scan(/^\d\d\d(.+)/)
                a = $stdin.gets
            end
        end
        
        return lines
    end

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