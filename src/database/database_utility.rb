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

module DatabaseUtility

    # Checks if the parameter is an array and returns the first element if so
    # otherwise returns the given element
    def DatabaseUtility.toInteger(array)
        if array.class.name == Array.to_s
            return array[0]
        else
            return array
        end
    end

    # Same as calling toInteger (see toInteger)
    def DatabaseUtility.toValue(array)
        return DatabaseUtility.toInteger(array)
    end

    # Assign the results from the database into a simple array
    def DatabaseUtility.fetch_results(query_object)
        rows = query_object.num_rows
        results = Array.new(rows)

        rows.times do |x|
            results[x] = query_object.fetch
        end

        return results
    end

    # Assign the results from the database into an array of associated hashes
    # Note: Does not handle when two columns are name the same name (if they are the second will overwrite the first)
    def DatabaseUtility.fetch_associated(query_object)
        associated_fields = query_object.result_metadata.fetch_fields
        results = Array.new

        query_object.num_rows.times do |x|
            results << Hash.new
            index = 0
            query_object.fetch.each do |element|

                results[x][associated_fields[index].name] = element
                index += 1
            end
        end

        return results
    end
end