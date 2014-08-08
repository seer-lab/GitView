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