class LineCounter
    def initialize()
        @singleLineComment = 0
        @inLineSingle = 0
        @inLineMulti = 0
        @multiLineCommentInLine = 0
        @multiLineComment = 0
        @linesOfCode = 0
    end

    def singleLineComment(value)
        @singleLineComment+=value        
    end

    def inLineSingle(value)
        @inLineSingle +=value        
    end

    def inLineMulti(value)
        @inLineMulti +=value        
    end

    def multiLineCommentInLine(value)
        @multiLineCommentInLine += value
    end

    def multiLineComment(value)
        @multiLineComment+=value     
    end

    def linesOfCode(value)
        @linesOfCode+=value
    end
end

class CodeChurn
    def initialize()
        @commentAdded = 0
        @commentDeleted = 0
        @commentModified = 0
        @codeAdded = 0
        @codeDeleted = 0
        @codeModified = 0
    end

    def commentAdded(value)
        @commentAdded+=value        
    end

    def commentDeleted(value)
        @commentDeleted +=value        
    end

    def commentModified(value)
        @commentModified +=value       
    end

    def codeAdded(value)
        @codeAdded +=value        
    end

    def codeDeleted(value)
        @codeDeleted += value
    end

    def codeModified(value)
        @codeModified += value
    end
end

class Linker
    def initialize()
        @comment = Array.new
        @source_code = Array.new
    end

    def push()
        pushComment()
        pushSourceCode()
    end

    def pushComment()
        @comment.push("")
    end

    def pushSourceCode()
        @source_code.push("")
    end

    def setComment(comment)
        @comment[@comment.size-1] += comment
    end

    def setSourceCode(source_code)
        @source_code[@source_code.size-1] += source_code
    end

    def getComment()
        @comment[@comment.size-1]
    end

    def getSourceCode()
        @source_code[@source_code.size-1]
    end
end

class CodeParser
    attr_accessor :test, :log, :high_threshold, :low_threshold, :size_threshold, :one_to_many

    def initialize(test, log, high_threshold, low_threshold, size_threshold, one_to_many)
        @test = test
        @log = log
        @high_threshold = high_threshold        
        @low_threshold = low_threshold
        @size_threshold = size_threshold
        @one_to_many = one_to_many        
    end
    # Identifies lines that have been added, deleted (and soon modified)
    # Also the line is classified as a comment or code. 
    # Note: the regular expression to identify comments and code require that the code
    # is changed (eg. removing the blocks of quoted text) inorder to be accurate
    def findMultiLineComments (lines)
        multiLine = false
        lineCounter = LineCounter.new
        codeLines = Array.new
        codeChurn = CodeChurn.new
        grouped = Linker.new
        commentLookingForMultiChild = false
        commentLookingForChild = false

        quoteManager = ManageQuotes.new

        method_finder = MethodFinder.new(lines)

        #linesModified = Array.new
        linesStreak = Hash.new
        linesStreak["-"] = Array.new
        linesStreak["+"] = Array.new
        linesCommentStreak = Hash.new
        linesCommentStreak["-"] = Array.new
        linesCommentStreak["+"] = Array.new
        patchNegStreak = 0
        patchPosStreak = 0
        patchPosPrev = 0
        patchNegPrev = 0
        totalCode = 0
        totalComment = 0

        lineCount = 0

        #puts patches
        #puts lines[0]
        #puts ""
        lines.each { |line|
            #Create a new grouping

            patchPosPrev = patchPosStreak
            patchNegPrev = patchNegStreak

            if !commentLookingForChild && !commentLookingForMultiChild
                grouped.push
            end

            quoteLessLine = quoteManager.removeQuotes(line[0])

            if @test
                puts "line = #{line[0]}"
                #puts "multi = #{multiLine}"
                #puts ""
            end

            # Identify if the current line is a method
            if method_finder.methodFinderManager(lineCount)
                # Find length of the method
                m_end = method_finder.methodEndFinder(lineCount+method_finder.delta+1)

                if @test
                    # Identifies the actual start of the method (prior is either white space or comments)
                    puts "actual_start = #{method_finder.actual_start}"
                    puts "comment_start = #{method_finder.comment_start}"
                    puts "###### method_start #{lineCount} ######"
                    puts lines[lineCount..m_end]
                    puts "####### method_end #{m_end} #######"
                end
            end

            if multiLine

                # A mutli-line comment has started but not finished. Check if it has ended.

                #TODO handle code proceeding the end of the multi-line comment
                result = quoteLessLine.scan(JAVA_MULTI_LINE_SECOND_HALF)[0]
                if result == nil
                    #Still part of the multi-line, terminating line has not be found
                    result = line

                    #Can remove empty comment lines
                    #if line[0].gsub(/\*/, '').match(/^\s*$/) == nil
                    lineCounter.multiLineComment(1)
                    
                    #puts "part of multi"
                else
                    #Found multi-line terminator
                    multiLine = false

                    #Can remove empty ending line
                    #if result[0].gsub(/[\*\/]/, '').match(/^\s*$/) == nil
                    lineCounter.multiLineComment(1)
                    #puts "end of multi"
                end
                
                if line[0][0] == "+"
                    patchPosStreak += 1
                    #puts "patch add streak #{patchPosStreak}"
                    linesCommentStreak["+"].push(line[0][1..-1])
                    
                    totalComment+=1
                    codeChurn.commentAdded(1)
                elsif line[0][0] == "-"
                    patchNegStreak += 1
                    #puts "patch neg streak #{patchNegStreak}"
                    linesCommentStreak["-"].push(line[0][1..-1])

                    totalComment-=1
                    codeChurn.commentDeleted(1)
                end
                
                #Set the grouping to the comment
                grouped.setComment("\n#{result[0]}")
                #comments[index] += "\n#{result[0]}"
            else
                # Check for whether there is a comment in the given line

                #Remove the quotes prior to checking it
                result = quoteLessLine.scan(JAVA_MULTI_LINE_FULL)
                
                result = result[0]
                if result != nil

                    comment = nil
                    # A full comment is in the line
                    if result[1] != nil || result[2] != nil

                        # Determine whether the line was added or deleted
                        if line[0][0] == "+"
                            patchPosStreak += 1
                            #puts "patch add streak #{patchPosStreak}"
                            linesCommentStreak["+"].push(line[0][1..-1])
                            codeChurn.commentAdded(1)
                            totalComment+=1
                        elsif line[0][0] == "-"
                            patchNegStreak += 1
                            #puts "patch neg streak #{patchNegStreak}"
                            linesCommentStreak["-"].push(line[0][1..-1])
                            codeChurn.commentDeleted(1)
                            totalComment-=1
                        end
                        
                        # Single Comment 'In-line'
                        if result[1] != nil 
                            #lineCounter.singleLineComment(1)
                            comment = result[1]

                        # Multi Comment 'In-line'
                        elsif result[2] != nil
                            #lineCounter.multiLineCommentInLine(1)
                            comment = result[2]
                        end

                        # Check whether there is source code at the beginning or the end of the line.
                        if (result[3] != nil && result[3][1..-1] != nil && result[3][1..-1].match(WHITE_SPACE) == nil) || (result[0] != nil && result[0][1..-1] != nil && result[0][1..-1].match(WHITE_SPACE) == nil)

                            if line[0][0] == "+"
                                #patchPosStreak += 1
                                #puts "patch add streak #{patchPosStreak}"
                                linesStreak["+"].push(line[0][1..-1])
                                codeChurn.codeAdded(1)
                                totalCode+=1
                            elsif line[0][0] == "-"
                                #patchNegStreak += 1
                                #puts "patch neg streak #{patchNegStreak}"
                                linesStreak["-"].push(line[0][1..-1])
                                codeChurn.codeDeleted(1)
                                totalCode-=1
                            end
                            #Stop looking for the code                        
                            commentLookingForChild = false
                        end

                        # Add the comment to the list of comments
                        #comments.push(comment)
                    end

                else

                    # Check if it is the beginning of a multi-line comment

                    #TODO handle multi-line comment starting on a line of code 
                    result = quoteLessLine.scan(JAVA_MULTI_LINE_FIRST_HALF)
                    if result[0] != nil
                        #There is a multi-line comment starting here
                        multiLine = true
                        #index = comments.size
                        #comments.push(result[0][0])
                        #lineCounter.multiLineComment(1)
                        if line[0][0] == "+"
                            patchPosStreak += 1
                            #puts "patch add streak #{patchPosStreak}"
                            linesCommentStreak["+"].push(line[0][1..-1])
                            codeChurn.commentAdded(1)
                            totalComment+=1
                        elsif line[0][0] == "-"
                            patchNegStreak += 1
                            #puts "patch neg streak #{patchNegStreak}"
                            linesCommentStreak["-"].push(line[0][1..-1])
                            codeChurn.commentDeleted(1)
                            totalComment-=1
                        end

                    else
                        #There is no comment on this line handle is a purely code
                        
                        if line[0][0] == "+"
                            patchPosStreak += 1
                            #puts "patch add streak #{patchPosStreak}"
                            linesStreak["+"].push(line[0][1..-1])

                            if line[0].match(WHITE_SPACE) == nil && line[0][1..-1].match(WHITE_SPACE) == nil
                                codeChurn.codeAdded(1)
                                totalCode+=1
                            end
                        elsif line[0][0] == "-"
                            patchNegStreak += 1
                            #puts "patch neg streak #{patchNegStreak}"
                            linesStreak["-"].push(line[0][1..-1])
                            if line[0].match(WHITE_SPACE) == nil && line[0][1..-1].match(WHITE_SPACE) == nil
                                codeChurn.codeDeleted(1)
                                totalCode-=1
                            end
                        end

                        #codeLines.push(line[0])
                        
                        if commentLookingForChild
                            #Code found store it in the grouping
                            #grouped.setSourceCode(line[0])
                            #Stop looking for the code
                            commentLookingForChild = false

                        end
                        
                    end
                end
            end

            if patchNegStreak > 0 && patchPosStreak > 0
                #puts "neg #{patchNegStreak}"
                #puts "pos #{patchPosStreak}"
                if patchNegPrev == patchNegStreak && patchPosPrev == patchPosStreak
                    
                    if @test || @log
                        #puts "streak over"

                        puts "Code Modified:"
                        linesStreak["-"].each { |negLine|
                            puts "- #{negLine}"
                        }
                        linesStreak["+"].each { |posLine|
                            puts "+ #{posLine}"
                        }

                        puts "Comment Modified:"
                        linesCommentStreak["-"].each { |negLine|
                            puts "- #{negLine}"
                        }
                        linesCommentStreak["+"].each { |posLine|
                            puts "+ #{posLine}"
                        }
                    end

                    # Please Note:
                    # Code modifications may be influenced by the comments being modified
                    # As well as comment modifications being influenced by the code being modified
                    # Example:
                    # - System.out.println("Hello World!"); //This line tells the world hello really loud
                    # + System.out.println("Hello World!"); //This prints out Hello World
                    # Currently this will show up as a modificiation for both code and comment
                    codeMod = Hash.new
                    commentMod = Hash.new
                    codeModLength = 0
                    
                    code_pid = Thread.new do
                        codeMod = findShortestDistance(linesStreak["+"], linesStreak["-"], @high_threshold, @low_threshold, @size_threshold, @one_to_many)

                        found = Hash.new
                        codeMod.each {|i,v|
                            v.each {|k, d|
                                if found[k] ==nil
                                    found[k] = true
                                end
                            }
                        }
                        codeModLength = found.length
                    end

                    #comment_pid = fork do
                    commentMod = findShortestDistance(linesCommentStreak["+"], linesCommentStreak["-"], @high_threshold, @low_threshold, @size_threshold, @one_to_many)
                    #end

                    found = Hash.new
                    commentMod.each {|i,v|
                        v.each {|k, d|
                            if found[k] ==nil
                                found[k] = true
                            end
                        }
                    }
                    commentModLength = found.length

                    # Wait for the results
                    code_pid.join
                    #Process.wait code_pid
                    #Process.wait comment_pid

                    #codeModLength = codeMod.length
                    #commentModLength = commentMod.length
                    
                    if @test || @log
                        codeMod.each { |n, v|
                            v.each{ |p, d|
                                puts "PosLine = #{linesStreak["+"][p]} => NegLine = #{linesStreak["-"][n]} => distance = #{d}"
                            }
                        }

                        commentMod.each { |n, v|
                            v.each{ |p, d|
                                puts "PosLine = #{linesCommentStreak["+"][p]} => NegLine = #{linesCommentStreak["-"][n]} => distance = #{d}"
                            }
                        }

                        puts "Number of calc code modifications #{codeModLength}"
                        puts "Number of calc comment modifications #{commentModLength}"
                    end

                    codeChurn.codeModified(codeMod.length)
                    codeChurn.commentModified(commentMod.length)

                    #comments added = comments added - # of positive lines modified
                    codeChurn.commentAdded((-1)*commentModLength)
                    #comments deleted = comments deleted - # of lines modified(since the mapping is 1 Negative to many Positve lines)
                    codeChurn.commentDeleted((-1)*commentMod.length)

                    codeChurn.codeAdded((-1)*codeModLength)
                    codeChurn.codeDeleted((-1)*codeMod.length)

                    #puts "mods = #{mods}"
                    #patchNegStreak, patchPosStreak = 0, 0

                    # Reset arrays 
                    #linesStreak["+"] = Array.new
                    #linesStreak["-"] = Array.new
                    #linesCommentStreak["+"] = Array.new
                    #linesCommentStreak["-"] = Array.new

                    #a = $stdin.gets 
                end
                
            end

            if patchNegStreak > 0 || patchPosStreak > 0
                #puts "neg #{patchNegStreak}"
                #puts "pos #{patchPosStreak}"
                if patchNegPrev == patchNegStreak && patchPosPrev == patchPosStreak
                    patchNegStreak, patchPosStreak = 0, 0

                    # Reset arrays 
                    linesStreak["+"] = Array.new
                    linesStreak["-"] = Array.new
                    linesCommentStreak["+"] = Array.new
                    linesCommentStreak["-"] = Array.new
                end
            end
            #puts "Comment #{grouped.getComment}"
            #puts "Code #{grouped.getSourceCode}"
            #puts ""
            #puts "in line single #{lineCounter.inLineSingle(0)}"
            #puts "in line multi #{lineCounter.inLineMulti(0)}"
            #puts "single #{lineCounter.singleLineComment(0)}"
            #puts "multiInline = #{lineCounter.multiLineCommentInLine(0)}"
            #puts "multi #{lineCounter.multiLineComment(0)}"
            #puts "code #{lineCounter.linesOfCode(0)}"

            #puts "commentAdded = #{codeChurn.commentAdded(0)}"
            #puts "commentDeleted = #{codeChurn.commentDeleted(0)}"
            #puts "codeAdded = #{codeChurn.codeAdded(0)}"
            #puts "codeDeleted = #{codeChurn.codeDeleted(0)}"
            #puts ""
            
            #a = $stdin.gets
            lineCount += 1
            method_finder.iterate
        }
        return [[totalComment, totalCode], codeLines, lineCounter, codeChurn]
    end
end