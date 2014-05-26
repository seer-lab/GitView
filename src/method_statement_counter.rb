require_relative 'method_types'

class MethodStatementCounter

    include MethodTypes

    attr_accessor :new_method, :deleted_method, :modified_method

    DEFAULT_VERSION = -1
    CODE = :code
    COMMENT = :comment
    ADDED = :added
    DELETED = :deleted

    def initialize
        @new_method = {'code' => 0, 'comment' => 0}
        @deleted_method = {'code' => 0, 'comment' => 0}
        @modified_method = {'code_added' => 0, 'comment_added' => 0, 'code_deleted' => 0, 'comment_deleted' => 0}

        # Each element contains { 'type', 'length'}
        @states = Array.new
    end

    def count_line(type, history)
        if !@states.empty?
            if type && (type == CODE || type == COMMENT)
                if @states.last['type'] == MethodTypes::ONLY_ADDED
                    # New method
                    @new_method[type.to_s] += 1

                elsif @states.last['type'] == MethodTypes::ONLY_DELETED
                    # Deleted method
                    @deleted_method[type.to_s] += 1

                elsif @states.last['type'] == MethodTypes::MODIFIED
                    # Modified method

                    if history && (history == ADDED || history == DELETED)
                        @modified_method["#{type}_#{history}"] += 1
                    else
                        raise "history incorrectly defined as #{history}"
                    end

                #elsif @states.last == MethodTypes::UNCHANGED ||
                #    @states.last == MethodTypes::INITIAL
                    # Modified method
                end
            else
                raise "type incorrectly defined as #{type}"
            end
            @states.last['length'] -= 1
        end 
    end

    def push_state(type, length)

        state = {'type' => type, 'length' => length}
        # FIFO
        #@states.insert(0, state)

        # First in Last out (FILO)
        @states.push(state)
    end

    def pop_state
        @states.pop
    end
end
