require_relative 'levenshtein'

$removeWhiteSpaces = false

# Threshold of 50%
THRESHOLD = 0.5


# The threshold is to simplistic to work perfectly
# 

# Get the threshold for determining if a line is a possible modification
def getThreshold (lineLength)
    return (lineLength*THRESHOLD).round()
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

def replaceWhiteSpaces(lines)
    if $removeWhiteSpaces
        for i in 0..lines.length-1
            lines[i] = lines[i].gsub(/\s/, '')
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
def findShortestDistance(posLines, negLines, whiteSpaces = false)

    $removeWhiteSpaces = whiteSpaces

    posLines = replaceWhiteSpaces(posLines)
    negLines = replaceWhiteSpaces(negLines)

    used = Hash.new
    
    similarityIndex = findSimilarLines(posLines, negLines)

    similarityIndex.each { |i, v|
        if i != nil && !v.empty?
            v.each { |k, e|
                if used[k] == nil 
                    used[k] = {i => e}
                    break
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
