require_relative 'manage_quotes'

class MethodFinder
    # Actual start indicates the actual starting line which contains the method's signature
    # Comment start indicates the starting position of the comments preceeding the method.
    # *note that white space may preceed the comment.
    # *note that the lack of a comment preceeding a method is denoted by a -1
    attr_accessor :actual_start, :comment_start#, :plus_minus

    def initialize(lines)
        @delta = 0
        @just_run = false
        @lines = lines
        @mq = ManageQuotes.new
        @plus_minus = false
        @actual_start = 0
        @comment_start = -1
    end

    def findMethod(index)
        start = index
        @actual_start = index
        @comment_start = -1
        found = false

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

            # Check if the line contains a comment
            if quoteLess.match(/(\/\/)|(\/\*)/) && @comment_start == -1
                @comment_start = index
            end

            # TODO handle deleted statement
            # TODO handle added statment
            if quoteLess[0] == '-'
                # Skip
                index += 1
                next
            end

            quoteLess = @mq.removeComments(quoteLess)

            # Check if there is a '{' in the sanitized statement
            
            if quoteLess.match(/;\s*(\/\/(.*?)|(\/\*.*?))?$/)
                # \(.*?;.*?;.*\) could use to remove 'for' semi-colons
                # Even with the purposed fix the desired goal is already achieved.
                # The purposed fix would also not handle the following:
                # for(int i = 0; //<= This would cause it be recognized as a statement
                #     i < 10; i++) {...}

                # Statement has ended
                index = start
                break
                # Move onto the next statement
            elsif quoteLess.match(/\}/)
                index = start
                break
            else
                #TODO remove +/- inside the statement, currently just removing
                #TODO handle +/- properly
                fullStatement = "#{fullStatement} #{quoteLess[1..-1]}"

                if quoteLess.match(/\{/)
                    
                    if fullStatement.match(/\s(new)\s+/) ||
                        fullStatement.match(/\s(if|else|elsif|while|for|switch)\s*\(/)
                        # Not a statement since it has has built-in command as part of it
                        index = start
                        break
                    elsif fullStatement.match(/\(([\w\<\>\?,\s]*)\)\s*(throws[\w,\s]*)?\{/)
                        # Note this will not catch interface's declaration of a method (since it has no body)
                        found = true
                        break
                    else
                        # Not a method declaration
                        index = start
                        break
                    end
                end
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

                # TODO handle deleted statement
                # TODO handle added statment
                if quoteLess[0] == '-'
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

    if value
        end_value = fm.methodEndFinder(i+fm.delta+1)
        puts "######### method: start = #{i} end = #{end_value} #########"

        puts lines[i..end_value]
    end

    i+= 1
    fm.iterate
end

=end