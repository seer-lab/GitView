require_relative 'manage_quotes'
require_relative 'regex'

class MethodFinder
    # Actual start indicates the actual starting line which contains the method's signature
    # Comment start indicates the starting position of the comments preceeding the method.
    # *note that white space may preceed the comment.
    # *note that the lack of a comment preceeding a method is denoted by a -1
    attr_accessor :actual_start, :comment_start, :deleted_statement, :methodHistory

    DELETED_DEFAULT = -1
    COMMENT_DEFAULT = -1

    INITIAL = -1
    UNCHANGED = 0
    ONLY_ADDED = 1
    ONLY_DELETED = 2
    MODIFIED = 3


    def initialize(lines)
        @delta = 0
        @just_run = false
        @lines = lines
        @mq = ManageQuotes.new
        @deleted_statement = DELETED_DEFAULT
        @actual_start = 0
        @comment_start = COMMENT_DEFAULT
        @methodHistory = INITIAL
    end

    def findMethod(index)
        start = index
        @actual_start = index
        @comment_start = COMMENT_DEFAULT
        found = false
        stop_looking = false
        @deleted_statement = DELETED_DEFAULT
        @methodHistory = INITIAL
        #end_of_block = false

        # Identify the method
        # 1. identify that the line is a possible method
        #     - aka not ending with semi-colon 
        #    - must have '{'
        #    - must not be if, else, elsif, while, for, switch
        #     - may be spawning over multiple lines
        #    - may have declaration of arguments (or no arguments)
        fullStatement = ""   

        while !found && index < @lines.length

            quoteLess = @mq.removeQuotes(@lines[index][0])

            # TODO handle deleted statement
            #if quoteLess[0] == '-' && false
            #    # Skip
            #    index += 1
            #    next
            #end
            if @deleted_statement != DELETED_DEFAULT && quoteLess[0] == '+'
                # Modified statement
                # Look for another method signature with + preceeding it
            elsif @deleted_statement != DELETED_DEFAULT && quoteLess[0] != ' '
                # Statement is only deleted continue where it was previously left at
                index = @deleted_statement
                found = true
                break
            end

            updateHistory(quoteLess)
            #puts "QuoteLess = #{quoteLess}"

            # Check if the line contains a comment
            if quoteLess[0] != '-' && quoteLess.match(/(\/\/)|(\/\*)/) && @comment_start == -1
                @comment_start = index
            end

            quoteLess = @mq.removeComments(quoteLess)

            # Check if there is a '{' in the sanitized statement
            
            if quoteLess.match(/;\s*$/)#(\/\/(.*?)|(\/\*.*?))?$/) # TODO REMOVE
                # \(.*?;.*?;.*\) could use to remove 'for' semi-colons
                # Even with the purposed fix the desired goal is already achieved.
                # The purposed fix would also not handle the following:
                # for(int i = 0; //<= This would cause it be recognized as a statement
                #     i < 10; i++) {...}

                stop_looking = true
                # Move onto the next statement
            elsif quoteLess.match(/\}/)
                #if !@deleted_statement
                #index = start
                #break
                #end
                stop_looking = true
            else
                #TODO remove +/- inside the statement, currently just removing
                #TODO handle +/- properly
                temp = "#{fullStatement} #{quoteLess[1..-1]}"
                #puts "full = #{fullStatement}"

                if quoteLess.match(/\{/)
                    
                    if temp.match(/\s(new)\s+/) ||
                        temp.match(/\s(if|else|elsif|while|for|switch)\s*\(/)
                        # Not a statement since it has has built-in command as part of it
                        stop_looking = true
                    elsif temp.match(/\(([\w\<\>\?,\s]*)\)\s*(throws[\w,\s]*)?\{/)
                        # Note this will not catch interface's declaration of a method (since it has no body)
                        
                        if quoteLess[0] == '-'
                            # A deleted method signature has been found 
                            @deleted_statement = index
                        else
                            found = true
                            break
                        end
                    else
                        # Not a method declaration
                        stop_looking = true
                    end
                end

                # Undo changes made by a negative line
                if quoteLess[0] != '-'
                    fullStatement = temp
                end
            end

            #puts "Stop #{stop_looking}"
            if stop_looking && @deleted_statement == DELETED_DEFAULT #&& quoteLess[0] != '-'
                #fullStatement = temp
                index = start
                break
            else
                # Undo changes made by a negative line
                stop_looking = false
            end

            index += 1

            if fullStatement.lstrip == ""
                @actual_start += 1
            end
        end

        # Extract useful info from it
        @delta = index - start

        # return number of lines the method signature takes up? 
        # Useful info:
        # - number of lines the method signature takes up
        #    - Can ignore the check for method for the number of lines the method signature takes up
        # - number of lines the method takes up
        return found
    end

    def updateHistory(line)
        if line[0] == '-'
            if @methodHistory == INITIAL
                @methodHistory = ONLY_DELETED 
            elsif @methodHistory == ONLY_ADDED || @methodHistory == UNCHANGED
                @methodHistory = MODIFIED
            end
        elsif line[0] == '+'
            if @methodHistory == INITIAL
                @methodHistory = ONLY_ADDED
            elsif @methodHistory == ONLY_DELETED || @methodHistory == UNCHANGED
                @methodHistory = MODIFIED
            end
        elsif line[1..-1] && line[1..-1].match(WHITE_SPACE) != nil &&
            @methodHistory != UNCHANGED #&& line[0] == ' '
            # Ensure the line isnt empty
            if @methodHistory == INITIAL
                @methodHistory = UNCHANGED
            else
                @methodHistory = MODIFIED
            end
        end
    end

    def methodFinderManager(index)

        #found = false
        #actual = 0
        if @delta == 0
            @just_run = true
            return findMethod(index)
        end
        #else#if @delta > 0
        @just_run = false
        #@delta -= 1
        #end

        return false
    end

    def delta
        @delta
    end

    def reset_delta
        @delta = 0
    end

    def iterate
        if !@just_run && @delta > 0
            @delta -= 1
        end
    end

    # Given the index of the line preceding the method declaration. 
    # Identifies the ending index of the method.
    # If no end is found (most likely malformed code) then the nil is returned
    def methodEndFinder(index)

        # Assume that a method has been found. Therefore assume count('}') == count('{') + 1
        depthCounter = 1
        start = index
        test = 0

        begin
            index = start
            while index < @lines.length

                if test == 1
                    puts "Line = #{@lines[index][0]}"
                    puts "index = #{index}"
                end

                quoteLess = @mq.removeQuotes(@lines[index][0])

                updateHistory(quoteLess) 

                # TODO handle deleted statement
                # TODO handle added statment
                if quoteLess[0] == '-' && @methodHistory == MODIFIED
                    # Skip
                    index += 1
                    next
                end

                quoteLess = @mq.removeComments(quoteLess)

                result = quoteLess.scan(/\{|\}/)

                if test == 1
                    puts "inComment? = #{@mq.commentOpen}"
                    puts "depth = #{depthCounter}"
                    puts "quoteLess = #{quoteLess}"
                    puts "Brackets = #{result}"
                end
                
                result.each do |cur|

                    if cur == '}'
                        # Decrement the count by 1
                        depthCounter -= 1

                        # Check for depth condition
                        if depthCounter == 0
                            break
                        end
                    end
                   
                    if cur == '{'
                        # Increment the count by 1
                        depthCounter += 1
                        #puts "depth Increased at #{@lines[index][0]}"
                        #puts "WITH #{result} and #{cur}"
                    end
                end

                if depthCounter == 0
                    return index
                end

                index += 1
            end

            test += 1

        end while test <= 1

        # No end found
        return nil
    end

    # Calculates how many statements were added, deleted or unchanged (will not work for modified since it 
    # just counts all the statements that are part of the method).
    # Also does not take into account comments vs code
    def method_length(method_end)
        length = 0

        # Capture comments within the count
        if @comment_start != -1
            length += actual_start - @comment_start
        end

        length += method_end - @actual_start

        # Convert from index to length
        length += 1
    end
end

=begin
text = 'public void onItemClick(AdapterView<?> parent, View view, int position,
        long id) {
    switch (position)
    {
        case ADD_CONTACT:
            //Launch add contacts
            AddContact.addContact = true;
            AddContact.editTc = null;
            ConversationView.this.startActivity(new Intent(
                    ConversationView.this.getBaseContext(), 
                    AddContact.class));
        break;
        case IMPORT_CONTACT:
            //Launch import contacts
            ConversationView.this.startActivity(new Intent(
                    ConversationView.this.getBaseContext(), 
                    ImportContacts.class));
        break;
    }

    for(int i = 0;
        i < 10; i++) {
        System.out.println ("public int add(int x, int y) { return x + y; }");
        AddContact.editTc = null;
    }
}
/* public int subtract(int x, int y) { return x - y; } */
// public int divide(int x, int y) { return x / y; }
public int divide(int x, int y) {
    return x / y; }
/*public int multiply(int x, int y)
{
    return x * y;
}*/

- public void findMenthod(String lines) {
-   return "";    
-}

- public void findMenthod(String lines) {
-   return "Hello";
+ public int findDonut(int lines) {
   return "";    
}

'
text = text[0..-1]
lines = text.split(/\n/)
fm = MethodFinder.new(lines)
i = 0
lines.each do |line|
    puts "line = #{line}"
    value = fm.methodFinderManager(i)
    #fm.methodFinderManager(i)
    puts "i = #{i}, found = #{value}, delta = #{fm.delta}"
    puts "deletedstatment = #{fm.deleted_statement}"

    if value
        end_value = fm.methodEndFinder(i+fm.delta+1)
        puts "######### method: start = #{i}, type = #{fm.methodHistory} #########"

        puts lines[i..end_value]
        puts "######### method_end #{end_value} #########"
    end

    i+= 1
    fm.iterate
end

=end