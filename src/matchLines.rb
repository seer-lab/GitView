require_relative 'levenshtein'

$removeWhiteSpaces = false

# Threshold of 50%
$THRESHOLD = 1.0
$ONE_TO_MANY = true


# The threshold is to simplistic to work perfectly
# 

# Get the threshold for determining if a line is a possible modification
def getThreshold (lineLength)
    return (lineLength*$THRESHOLD).round()
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

            # Pick the the length of the longest line.
            # So additions that are smaller than the negative counter part are not favoured. 
            largeLength = posLine.length
            if negLine.length > largeLength
                largeLength = negLine.length
            end

            #Check if it is above threshold
            if similarityIndex[i][j] < getThreshold(largeLength)

                #similarityIndex[i][j] = levenshtein(posLine, negLine)
                shortest[i][j] = similarityIndex[i][j]
            end
            j+=1
        }
        #puts "shortest = #{shortest[i]}"
        shortest[i] = constructHash(shortest[i].sort_by { |k,v| v })
        #puts "a shortest = #{shortest[i]}"
        i+=1
        j=0
    }
    #puts "bf shortest = #{shortest}"
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

# Removes all white spaces within the lines
# @return the lines without white spaces
def replaceWhiteSpaces(lines, type = 0)
    if $removeWhiteSpaces
        for i in 0..lines.length-1
            if type == 0
                lines[i] = lines[i].gsub(/\s/, '')
            elsif type == 1
                lines[i].strip!
            elsif type == 2
                lines[i].lstrip!
            end
        end
    end
    return lines
end

# Determine which positive lines have the shortest exclusive distance a negative line
# As part of this no 2 positive lines can be related in similarity to a single negative line
# Note: white spaces can be removed, but by default are kept
# 
# It however does not use a stable sorting algorithm and thus could
# provide different pairings for lines that tie. Details given here:
# http://stackoverflow.com/questions/15442298/is-sort-in-ruby-stable
def findShortestDistance(posLines, negLines, threshold = 0.5, one_to_many = false, whiteSpaces = false)

    $THRESHOLD = threshold.to_f
    $ONE_TO_MANY = one_to_many
    $removeWhiteSpaces = whiteSpaces

    posLines = replaceWhiteSpaces(posLines)
    negLines = replaceWhiteSpaces(negLines)

    used = Hash.new
    
    # Positive Line Number => {Negative Line Number => distance}
    similarityIndex = findSimilarLines(posLines, negLines)

    # i = current Positive Line Number
    # v = the pairs of {Negative Line Number => distance} that the current i maps to
    # k = the current Negative Line Number (one of, if any, that i maps to)
    # d = the distance calculated between posLines[i] and negLines[k]
    # used = the hash of values mapped by Negative Line Number => {Postive Line Number => distance}
    # it also indicates which mappings between positive and negative lines 
    similarityIndex.each { |i, v|
        if i != nil && !v.empty?
            v.each { |k, d|
                if used[k] == nil
                    used[k] = {i => d}
                    if !$ONE_TO_MANY
                        break
                    end
                elsif $ONE_TO_MANY && used[k][used[k].keys[0]] > d
                    used[k].delete(used[k].keys[0])
                    used[k] = {i => d}
                end

            }
            
        end
    }

    #Negative Line Number => {Positive Line Number => distance}
    #puts "used = #{used}"
    return used
end
