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

require_relative 'levenshtein'

$removeWhiteSpaces = false

# HIGH_THRESHOLD of 50%

# TODO make set able (from file_parser)
$HIGH_THRESHOLD = 0.5
$LOW_THRESHOLD = 0.8
$SIZE_TRESHOLD = 20
$ONE_TO_MANY = true


# The HIGH_THRESHOLD is to simplistic to work perfectly
# 

# Get the HIGH_THRESHOLD for determining if a line is a possible modification
def getTreshold (lineLength)
    if lineLength < $SIZE_TRESHOLD
        return (lineLength*$LOW_THRESHOLD).round()
    else
        return (lineLength*$HIGH_THRESHOLD).round()
    end
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
            largeLength = [posLine.length, negLine.length].max

            #Check if it is above HIGH_THRESHOLD
            if similarityIndex[i][j] < getTreshold(largeLength)

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
def findShortestDistance(posLines, negLines, high_threshold = 0.5, low_threshold = 0.8, size_threshold = 0.5, one_to_many = false, whiteSpaces = false)

    $HIGH_THRESHOLD = high_threshold.to_f
    $LOW_THRESHOLD = low_threshold.to_f
    $SIZE_TRESHOLD = size_threshold.to_i
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
