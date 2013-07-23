require_relative 'levenshtein'

# Get the threshold for determining if a line is a possible modification
# Currently it is the length of the line divided by 2
def getThreshold (lineLength)
    return (lineLength/2.0).round()
end

# Using levenshtein's calculation for string similarity the list of similar lines is calculated
# The list returned is an ordered hash table containing all the valid entries of line similarities
# mapped as:
# Positive Line Index => { Negative Line Index => Distance }
# Note that this method uses instable sorts
def findSimilarLines(posLines, negLines)
    similarityIndex = Array.new

    #array of the indexs shorted by the shortest at 0 to the largest at n
    shortest = Hash.new

    i = 0
    j = 0
    posLines.each { |posLine|

        similarityIndex[i] = Array.new
        shortest[i] = Hash.new
        negLines.each { |negLine|

            similarityIndex[i][j] = levenshtein(posLine, negLine)
            #Check if it is above threshold
            if similarityIndex[i][j] < getThreshold(posLine.length)

                #similarityIndex[i][j] = levenshtein(posLine, negLine)
                shortest[i][j] = similarityIndex[i][j]
            end
            j+=1
        }
        shortest[i] = constructHash(shortest[i].sort_by { |k,v| v })
        i+=1
        j=0
    }
    return constructHash(shortest.sort_by { |h,v| v.keys && v.values })
end

# Take a sorted array and map the index to the element values
# This will work on an array containing any values as long as 
# the parameter passed is an array.
def constructHash(sortedArray)
    newHash = Hash.new

    sortedArray.each { |element|
        newHash[element[0]] = element[1]
    }

    return newHash
end

# Determine which positive lines have the shortest exclusive distance a negative line
# As part of this no 2 positive lines can be related in similarity to a single negative line
# 
# It however does not use a stable sorting algorithm and thus could
# provide different pairings for lines that tie. Details given here:
# http://stackoverflow.com/questions/15442298/is-sort-in-ruby-stable
def findShortestDistance(posLines, negLines)

    used = Hash.new
    
    similarityIndex = findSimilarLines(posLines, negLines)

    similarityIndex.each { |i, v|
        if i != nil && !v.empty?
            v.each { |k, e| 
                if used[k] == nil 
                    used[k] = {i => e}
                end
            }
            
        end
    }

    used.each { |n, v|
        v.each{ |p, d|
            puts "PosLine = #{posLines[p]} => NegLine = #{negLines[n]} => distance = #{d}"
        }
    }
    #Negative Line Number => {Positive Line Number => distance}
    #puts "used = #{used}"
    return used
end
