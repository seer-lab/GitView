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

    def to_s
        return "s+ = #{@new_method}, s- = #{@deleted_method}, s~ = #{@modified_method}"
    end
end
