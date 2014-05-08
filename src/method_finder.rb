require_relative 'manage_quotes'

# TODO make sure that line is sanitized (no quoted strings)
# TODO handle comments (replace them with empty comments for parsing)
class MethodFinder

    def initialize(lines)
        @delta = 0
        @just_run = false
        @lines = lines
        @mq = ManageQuotes.new
    end

    def findMethod(index)
        start = index
        found = false

        # Identify the method
        # 1. identify that the line is a possible method
        #     - aka not ending with semi-colon 
        #    - must have '{'
        #    - must not be if, else, elsif, while, for, switch
        #     - may be spawning over multiple lines
        #    - may have declaration of arguments (or no arguments)      

        while !found && index < @lines.length

            #TODO ensure that the [0] is necessary
            quoteLess = @mq.removeQuotes(@lines[index])

            # Check if there is a '{' in the sanitized statement
            if quoteLess.match(/\{/)

                prev = @mq.prevOpen
                @mq.prevOpen = false

                # Ensure that it is not a built-in primative function (as stated earlier)

                # Take previous lines involved to make full statement and check
                sindex = start
                fullStatement = ""
                while sindex <= index
                    fullStatement = "#{fullStatement} #{@mq.removeQuotes(@lines[sindex])}"
                    sindex += 1
                end

                @mq.prevOpen = prev

                if fullStatement.match(/\s(if|else|elsif|while|for|switch)\s*\(/)
                    # Not a statement since it has has built-in command as part of it
                    break
                elsif fullStatement.match(/\(([\w\<\>\?,\s]*)\)\s*\{/)
                    found = true
                    break
                end
            elsif quoteLess.match(/;\s*(\/\/(.*?)|(\/\*.*?))?$/)
                # \(.*?;.*?;.*\) could use to remove 'for' semi-colons
                # Even with the purposed fix the desired goal is already achived.
                # The purposed fix would also not handle the following:
                # for(int i = 0; //<= This would cause it be reconized as a statement
                #     i < 10; i++) {...}

                # Statement has ended
                break
                # Move onto the next statement
            end
            index += 1
        end

        # Extract useful info from it
        methodSignatureLength = index - start

        # return number of lines the method signature takes up? 
        # Useful info:
        # - number of lines the method signature takes up
        #    - Can ignore the check for method for the number of lines the method signature takes up
        # - number of lines the method takes up
        return [methodSignatureLength, found]
    end

    def methodFinderManager(index)

        found = false
        if @delta == 0
            @just_run = true
            @mq.prevOpen = false
            @delta, found = findMethod(index)
        else#if @delta > 0
            @just_run = false
            #@delta -= 1
        end

        return found
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

    # Given the index of the line preceeding the method declartion. 
    # Identifies the ending index of the method.
    # If no end is found (most likely malformed code) then the nil is returned
    def methodEndFinder(index)

        # Assume that a method has been found. Therfore assume count('}') == count('{') + 1
        depthCounter = 1
        @mq.prevOpen = false

        while index < @lines.length

            quoteLess = @mq.removeQuotes(lines[index])

            result = quoteLess.scan(/\{|\}/)

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
                end
               end

               if depthCounter == 0
                   return index
               end

            index += 1
        end
        # No end found
        return nil
    end
end

#=begin
text = "public void onItemClick(AdapterView<?> parent, View view, int position,
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
        System.out.println (\"public void add(int x, int y) { return x + y; }\");
        AddContact.editTc = null;
    }
}"
text = text[0..-1]
lines = text.split(/\n/)
fm = MethodFinder.new(lines)
i = 0
lines.each do |line|
    puts "line = #{line}"
    value = fm.methodFinderManager(i)
    #fm.methodFinderManager(i)
    puts "i = #{i}, found = #{value}, delta = #{fm.delta}"
    i+= 1
    fm.iterate
end
#=end