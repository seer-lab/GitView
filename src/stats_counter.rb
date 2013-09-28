require_relative 'utility'
require_relative 'regex'
require_relative 'stats_db_interface'

$high_threshold, $ONE_TO_MANY = 0.5, true
$low_threshold, $size_threshold = 0.8, 20
$test = true

def mergeThreshold(threshold)
    threshold = ((threshold.to_f*10).to_i).to_s
    if threshold.length == 1 
        threshold = "0#{threshold}"
    end
    return threshold
end

def getAllRepoCounts(con, repo_owner, repo_name)
    pick = con.prepare("SELECT DISTINCT c.commit_date, c.total_comment_addition, c.total_comment_deletion, c.total_comment_modified, c.total_code_addition, c.total_code_deletion, c.total_code_modified FROM repositories AS r INNER JOIN commits AS c ON r.repo_id = c.repo_reference INNER JOIN user AS com ON c.committer_id = com.user_id INNER JOIN user AS aut ON c.author_id = aut.user_id INNER JOIN file AS f ON c.commit_id = f.commit_reference WHERE r.repo_name LIKE ? AND r.repo_owner LIKE ? AND f.path LIKE ? ORDER BY c.commit_date")
    pick.execute(repo_name, repo_owner, "%")

    rows = pick.num_rows
    values = Array.new(rows)

    results = {'date' => Array.new, 'total_comments' => Array.new, 'total_comments_modified' => Array.new, 'total_code' => Array.new, 'total_code_modified' => Array.new}

    rows.times do |x|

        #values[x] indexs follow:
        # 0 = date, 1 = total comments added, 2 = total comments deleted, 3 = total comments modified, 4 = total code added, 5 total code deleted, 6 total code modified 
        values[x] = pick.fetch

        if x > 0 then
            results['total_comments'][x] = results['total_comments'][x-1]
            results['total_code'][x] = results['total_code'][x-1]

            results['total_comments_modified'][x] = results['total_comments_modified'][x-1]
            results['total_code_modified'][x] = results['total_code_modified'][x-1]
        elsif x == 0 then
            # Set the intial values to 0
            results['total_comments'][x] = 0
            results['total_code'][x] = 0

            results['total_comments_modified'][x] = 0
            results['total_code_modified'][x] = 0
        end

        results['date'][x] = values[x][0]

        results['total_comments'][x] += values[x][1] - values[x][2]
        results['total_code'][x] += values[x][4] - values[x][5]

        results['total_comments_modified'][x] += values[x][3]
        results['total_code_modified'][x] += values[x][6] 
    end

    #results.each { |x| puts x }
    return results
end

def getStartAndFinish(con, repo_owner, repo_name)
    values = getAllRepoCounts(con, repo_owner, repo_name)

    #subEntry = {'date' => 0, 'amount' => 0}
    #entries = {'first' => 0, 'last' => 0}
    results = {'date' => {'first' => 0, 'last' => 0}, 'total_comments' => {'first' => 0, 'last' => 0}, 'total_comments_modified' => {'first' => 0, 'last' => 0}, 'total_code' => {'first' => 0, 'last' => 0}, 'total_code_modified' => {'first' => 0, 'last' => 0}}

    results['date']['first'] = values['date'][0]
    results['date']['last'] = values['date'][-1]

    results['total_comments']['first'] = values['total_comments'][0]
    results['total_comments']['last'] = values['total_comments'][-1]

    results['total_comments_modified']['first'] = values['total_comments_modified'][0]
    results['total_comments_modified']['last'] = values['total_comments_modified'][-1]

    results['total_code']['first'] = values['total_code'][0]
    results['total_code']['last'] = values['total_code'][-1]

    results['total_code_modified']['first'] = values['total_code_modified'][0]
    results['total_code_modified']['last'] = values['total_code_modified'][-1]

    return results
end

def prettyPrint(results)

    #result.each { |type, values| values.each {|i, value| puts value} }
    results.each { |type, values|

        puts type
        values.each{|index, value|
            puts "\t#{index} #{value}"
        }
    }
end

def getNumberOfTags(con, repo_id)
	pick = con.prepare("SELECT count(t.tag_id) FROM repositories AS r INNER JOIN tags AS t ON r.repo_id = t.repo_reference WHERE r.repo_id = ?")
    pick.execute(repo_id)

    return Utility.toInteger(pick.fetch)
end

stats_con = Stats_db.createConnectionThreshold("#{$size_threshold.to_s}_#{mergeThreshold($low_threshold)}_#{mergeThreshold($high_threshold)}", $ONE_TO_MANY)



repo = 0

repo = Stats_db.getRepos(stats_con)

repo.each { |repo_id, repo_name, repo_owner|

    results = getStartAndFinish(stats_con, repo_owner, repo_name)

    puts "Repo = #{repo_owner}/#{repo_name}"
    prettyPrint(results)


    numberOfTags = getNumberOfTags(stats_con, repo_id)

    if numberOfTags == 0 then
    	numberOfTags = "N/A"
    end
    puts "Number of Tags: #{numberOfTags}"
    puts ""
}