require 'pg'

class DBinterface

    USERNAME = "postgres"
    PASSWORD = ""

    # Default port
    PORT = '5433' #'5432'

    PREDICT_DIFFERENCE = '5' #buffer_size(c.commit_date, c.repo_reference)::integer

    def initialize(name)
        @conn = PG.connect(dbname: name, user: USERNAME, password: PASSWORD, hostaddr: "127.0.0.1", port: PORT)
    end

    def insert(table, attributes)

        #attribute_list = prepare_values(attributes.values).join(", ")
        attribute_name_list = attributes.keys.join(", ")
        list = prepare_statement_list(attributes.size).join(",")

        query = "INSERT INTO 
                #{table}
            (
                #{attribute_name_list}
            )
            VALUES 
            (
                #{list}
            )
            RETURNING #{table}_id"

        id = nil
        @conn.exec_params(query, attributes.values) do |results|
            results.each do |value|
                id = value["#{table}_id"]
            end
        end
        return id
    end

    def get_id_existing(table, identifier)

        #attribute_values = prepare_values(identifier.values)
        attribute_name_list = identifier.keys
    
        # This would also force the insert to be prepared as well.
        attribute_list = set_prepare(attribute_name_list)

        query = "SELECT 
                #{table}_id
            FROM 
                #{table}
            WHERE
                #{attribute_list}"

        params = create_params(identifier.values)

        id = nil
        @conn.exec_params(query, params) do |results|
            results.each do |value|
                id = value["#{table}_id"]
            end
        end
        return id
    end

    def get_entries(table, attributes)

        attribute_name_list = attributes.join(", ")

        i = 0
        values = Array.new

        # Could add prepare here.
        @conn.exec("
            SELECT 
                #{attribute_name_list}
            FROM 
                #{table}
            ") do |results|
            results.each_row do |row|
                values[i] = Hash.new
                row.each_with_index do |element, j|
                    # Retrieve the values and store them into an array hash
                   values[i][attributes[j]] = element
                end
                i += 1
            end
        end
        return values
    end

     # Unique is the hash identifying how to find the entry
    def insert_nonexist(table, unique, input)
        id = get_id_existing(table, unique)

        if id == nil
            # Insert the information
            id = insert(table, input)
        end
        return id
    end

    def get_date_range(repo_owner, repo_name, train_size=100, test_size=nil, part=nil)
        if part != nil && part < 0
            part = nil
        end

        if train_size == nil
            return
        end

        if test_size == nil
            test_size = train_size
        end

        #att_names = ['quarter_0', 'quarter_1', 'quarter_2', 'quarter_3', 'quarter_4']

        data = get_date_range_commit(repo_owner, repo_name, train_size, test_size)

        # Pick the values to return
        if part != nil
            if part > data.size
                return [data[-1]]
            end            
            return [data[part]]
        end

        return data
    end

    def get_date_range_commit(repo_owner, repo_name, train_size, test_size)

        att_names = ['min', 'start', 'buffer', 'current', 'end']

        query = "
            with time_ranges as 
            (
                select
                    min(c.commit_date) OVER (ORDER BY c.commit_date) AS min,
                    lag(c.commit_date, $3 + #{PREDICT_DIFFERENCE}) OVER (ORDER BY c.commit_date) AS start,
                    lag(c.commit_date, #{PREDICT_DIFFERENCE}) OVER (ORDER BY c.commit_date) AS buffer,
                    c.commit_date as current,
                    lead(c.commit_date, $4) OVER (ORDER BY c.commit_date) AS end
                from
                    repositories as r INNER JOIN
                    commits as c ON r.repo_id = c.repo_reference
                where
                    r.repo_name = $1 AND
                    r.repo_owner = $2
            )
            select
                *
            from
                time_ranges as t
            where
                t.end IS NOT NULL AND
                t.start IS NOT NULL"


        i = 0
        values = Array.new

        params = create_params([repo_name, repo_owner, train_size, test_size])

        # Could add prepare here.
        @conn.exec_params(query, params) do |results|
            results.each_row do |row|
                values[i] = Hash.new
                row.each_with_index do |element, j|
                    # Retrieve the values and store them into an array hash
                   values[i][att_names[j]] = element
                end
                i += 1
            end
        end

        return values
    end

    # TODO  width, min_date
    def get_svm_data(repo_owner, repo_name, start_date, end_date, limit, width, min_date, train=false)

        #'name',
        #'committer', 
        #'previous_change_type',
        #'signature'
        #'change_type',
        #'length',
        #'short_change_freq',
        #'has_prev',
        #'previous_change_type',
        att_names = [ 'method_info_id', 'committer', 'signature', 'name', 'change_frequency', 'length', 'previous_change_type', 'has_prev','has_next']

        #v.name,
        #v.committer,
        #v.signature,
        #v.change_type,
        #v.short_change_freq,
        #v.length,
        #v.has_prev,
        #v.previous_change_type,
        query = "select 
            v.method_info_id,
            v.committer,
            v.signature,
            v.name,
            v.change_frequency,
            v.length,
            v.previous_change_type,
            v.has_prev,
            v.has_next
        from
            (select
                c.commit_id,
                f.name,
                mi.method_info_id,
                mi.signature,
                mi.length,
                CASE WHEN mi.change_type > 0 THEN 1 ELSE 0 END As change_type,
                c.commit_date,
                com.name as committer,
                exists_in_commits(c.repo_reference, c.commit_date, f.path, f.name, mi.signature, $5, $6) / LEAST(pcc.previous_commit_count::float, $5) as change_frequency,
                exists_in_commits(c.repo_reference, c.commit_date, f.path, f.name, mi.signature, 10, $6) / LEAST(pcc.previous_commit_count::float, 10) as short_change_freq,
                previous_change_type(c.repo_reference, c.commit_date, f.path, f.name, mi.signature),
                has_prev_commit(c.repo_reference, c.commit_date, f.path, f.name, mi.signature, #{PREDICT_DIFFERENCE}) as has_prev,
                has_next_commit(c.repo_reference, c.commit_date, f.path, f.name, mi.signature, #{PREDICT_DIFFERENCE}) as has_next
            from
                repositories as r INNER JOIN 
                commits as c ON r.repo_id = c.repo_reference INNER JOIN
                users as com ON c.committer_id = com.user_id INNER JOIN
                file as f ON c.commit_id = f.commit_reference INNER JOIN
                method as m ON f.file_id = m.file_reference INNER JOIN
                method_info as mi ON m.method_id = mi.method_id INNER JOIN
                current_commit_count as pcc ON pcc.commit_id = c.commit_id
            where 
                r.repo_name = $1 AND
                r.repo_owner = $2) as v
        where
            v.commit_date > $3 AND
            v.commit_date < $4 
        "

            #AND
                #f.path LIKE 'storm-core/src/jvm/org/apache/storm/%'
        #limit $6
        #order by
        #    random()

        values = [Array.new, Array.new]

        #i = 0
        #2.times do |category|
        category = nil

        if train
            start_date = min_date
        end
            
        params = create_params([repo_name, repo_owner, start_date, end_date, width, min_date])#, limit/2])
        # Could add prepare here.
        @conn.exec_params(query, params) do |results|
            results.each_row do |row|

                category = row[-1].to_i

                values[category] << Hash.new
                row.each_with_index do |element, j|
                    # Retrieve the values and store them into an array hash
                   values[category][-1][att_names[j]] = element
                end
                #i += 1
            end
        end
        #end

        first_size = (values[0].size * (limit)).to_i

        second_size = (values[1].size * (limit)).to_i

        puts "first = #{first_size}, second = #{second_size}"

        if first_size > second_size

            # Second dataset is larger than the first
            difference = second_size - first_size
            if difference > first_size
                values[1] +=  values[1]
                first_size += first_size

                # Datasets are still uneven, undersample
                second_size = first_size
            
            else
                values[1] +=  values[1][0..difference]
                first_size += difference
            end

        else
            difference = first_size - second_size
            if difference > second_size
                values[1] +=  values[1]
                second_size += second_size

                # Datasets are still uneven, undersample
                first_size = second_size
            else
                values[1] +=  values[1][0..difference]
                second_size += difference
                #difference -= second_size
            end
        end

        puts "first = #{first_size}, second = #{second_size}"

        result = values[0][0..first_size-1] + values[1][0..second_size-1]
        
        puts "Result: size = #{result.size}"
        #puts result[65..result.size-1]

        
        return result
    end

    def get_class_data(repo_owner, repo_name, start_date, end_date, limit, width, min_date, train=false)

        #'name',
        #'committer', 
        #'previous_change_type',
        #'signature'
        #'change_type',
        #'length',
        #'short_change_freq',
        #'has_prev',
        #'previous_change_type',
        att_names = ['committer','name', 'signature', 'change_frequency', 'short_change_freq', 'previous_change_type', 'has_prev', 'has_next']

        #v.name,
        #v.committer,
        #v.signature,
        #v.change_type,
        #v.short_change_freq,
        #v.length,
        #v.has_prev,
        #v.previous_change_type,
        query = "select
            v.committer,
            v.path,
            v.name,
            v.change_frequency,
            v.short_change_freq,
            v.previous_class_change_type,
            v.has_prev,
            v.has_next
        from
            (select
                c.commit_id,
                f.path,
                f.name,
                c.commit_date,
                com.name as committer,
                exists_in_commits_class(c.repo_reference, c.commit_date, f.path, f.name, $5) / LEAST(pcc.previous_commit_count::float, $5) as change_frequency,
                exists_in_commits_class(c.repo_reference, c.commit_date, f.path, f.name, 10) / LEAST(pcc.previous_commit_count::float, 10) as short_change_freq,
                previous_class_change_type(c.repo_reference, c.commit_date, f.path, f.name),
                has_prev_commit_class(c.repo_reference, c.commit_date, f.path, f.name, #{PREDICT_DIFFERENCE}) as has_prev,
                has_next_commit_class(c.repo_reference, c.commit_date, f.path, f.name, #{PREDICT_DIFFERENCE}) as has_next
            from
                repositories as r INNER JOIN 
                commits as c ON r.repo_id = c.repo_reference INNER JOIN
                users as com ON c.committer_id = com.user_id INNER JOIN
                file as f ON c.commit_id = f.commit_reference INNER JOIN
                method as m ON f.file_id = m.file_reference INNER JOIN
                method_info as mi ON m.method_id = mi.method_id INNER JOIN
                current_commit_count as pcc ON pcc.commit_id = c.commit_id
            where 
                r.repo_name = $1 AND
                r.repo_owner = $2) as v
        where
            v.commit_date > $3 AND
            v.commit_date < $4 
        "

            #AND
                #f.path LIKE 'storm-core/src/jvm/org/apache/storm/%'
        #limit $6
        #order by
        #    random()

        values = [Array.new, Array.new]

        #i = 0
        #2.times do |category|
        category = nil

        if train
            start_date = min_date
        end
            
        params = create_params([repo_name, repo_owner, start_date, end_date, width])#min_date, limit/2])
        puts params
        # Could add prepare here.
        @conn.exec_params(query, params) do |results|
            results.each_row do |row|

                category = row[-1].to_i

                values[category] << Hash.new
                row.each_with_index do |element, j|
                    # Retrieve the values and store them into an array hash
                   values[category][-1][att_names[j]] = element
                end
                #i += 1
            end
        end
        #end


        puts "first_o_size = #{values[0].size}, #{limit}"
        puts "second_o_size = #{values[1].size}"
        first_size = (values[0].size * (limit)).to_i

        second_size = (values[1].size * (limit)).to_i

        puts "first = #{first_size}, second = #{second_size}"

        if first_size > second_size

            # Over sample
            difference = first_size - second_size
            if difference > second_size
                values[1] +=  values[1]
                second_size += second_size

                # Datasets are still uneven, undersample
                first_size = second_size
            else
                values[1] +=  values[1][0..difference]
                second_size += difference
                #difference -= second_size
            end
        else

            # Second dataset is larger than the first
            difference = second_size - first_size
            if difference > first_size
                values[1] +=  values[1]
                first_size += first_size

                # Datasets are still uneven, undersample
                second_size = first_size
            
            else
                values[1] +=  values[1][0..difference]
                first_size += difference
            end
        end
        puts "first = #{first_size}, second = #{second_size}"

        result = values[0][0..first_size-1] + values[1][0..second_size-1]
        
        puts "Result: size = #{result.size}"
        #puts result[65..result.size-1]

        
        return result
    end

    def get_method_data(repo_owner, repo_name, method, end_date, limit)
    #def get_svm_data(repo_owner, repo_name, start_date, end_date, limit)
        #'name',
        #'committer', 
        #'previous_change_type',
        #'signature',
        #
        att_names = [ 'method_info_id', 'signature', 'change', 'change_frequency', 'length', 'has_prev', 'has_next']

        #v.name,
        #v.committer,
        #v.previous_change_type,
        #v.signature,
        #v.length,
        query = "select 
            v.method_info_id,
            v.signature,
            v.change_type,
            v.change_frequency,
            v.length,
            v.has_prev,
            v.has_next
        from
            (select
                c.commit_id,
                f.name,
                mi.method_info_id,
                mi.signature,
                mi.length,
                CASE WHEN mi.change_type > 0 THEN 1 ELSE 0 END As change_type,
                c.commit_date,
                com.name as committer,
                exists_in_commits(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) / pcc.previous_commit_count::float as change_frequency,
                previous_change_type(c.repo_reference, c.commit_date, f.path, f.name, mi.signature),
                has_prev_commit(c.repo_reference, c.commit_date, f.path, f.name, mi.signature, #{PREDICT_DIFFERENCE}) as has_prev,
                has_next_commit(c.repo_reference, c.commit_date, f.path, f.name, mi.signature, #{PREDICT_DIFFERENCE}) as has_next
            from
                repositories as r INNER JOIN 
                commits as c ON r.repo_id = c.repo_reference INNER JOIN
                users as com ON c.committer_id = com.user_id INNER JOIN
                file as f ON c.commit_id = f.commit_reference INNER JOIN
                method as m ON f.file_id = m.file_reference INNER JOIN
                method_info as mi ON m.method_id = mi.method_id INNER JOIN
                current_commit_count as pcc ON pcc.commit_id = c.commit_id
            where 
                r.repo_name = $1 AND
                r.repo_owner = $2 AND
                mi.signature = 'String[] getCrashReportFilesList() {') as v
        where
            v.commit_date < '2011-06-07 21:56:12-04'
        order by
            random()"

            #AND
                #f.path LIKE 'storm-core/src/jvm/org/apache/storm/%'
        #limit $6
        #order by
        #    random()

        values = [Array.new, Array.new]

        #i = 0
        #2.times do |category|
        category = nil
            
        params = create_params([repo_name, repo_owner])#, start_date, end_date, method])#, limit/2])
        # Could add prepare here.
        @conn.exec_params(query, params) do |results|
            results.each_row do |row|

                category = row[-1].to_i

                values[category] << Hash.new
                row.each_with_index do |element, j|
                    # Retrieve the values and store them into an array hash
                   values[category][-1][att_names[j]] = element
                end
                #i += 1
            end
        end
        #end


        puts "first_o_size = #{values[0].size}, #{limit}"
        puts "second_o_size = #{values[1].size}"
        first_size = (values[0].size * (limit)).to_i

        second_size = (values[1].size * (limit)).to_i

        puts "first = #{first_size}, second = #{second_size}"

        result = values[0][0..first_size-1] + values[1][0..second_size-1]
        
        puts "Result: size = #{result.size}"
        #puts result[65..result.size-1]

        
        return result
    end

private

    def create_params(values)
        values_list = Array.new
        i = 0
        values.each do |val|
            values_list << Hash.new
            values_list[i][:value] = val
            # Format is assumed to be a string
            values_list[i][:format] = 0
            i+=1
        end
        return values_list
    end

    def set_equal(attribute_list, attribute_value)
        test = ""
        attribute_list.each_with_index do |attribute, index|
            test += "#{attribute} = #{attribute_value[index]}"
            if index + 1 < attribute_list.size
                test += " AND "
            end
        end
        return test
    end

    def set_prepare(attribute_list)
        test = ""
        attribute_list.each_with_index do |attribute, index|
            test += "#{attribute} = $#{index+1}"
            if index + 1 < attribute_list.size
                test += " AND "
            end
        end
        return test
    end

    def prepare_statement_list(size)
        result = Array.new
        size.times do |x|
            result << "$#{x+1}"
        end
        return result
    end

    def prepare_values(values)
        values.map do |value|
            # handle the case where a string needs to be escaped
            if value.class.name == "String"
                value = "'#{value}'"
            else
                value
            end
        end
    end

end

=begin
            # Second dataset is larger than the first
            difference = second_size - first_size
            if difference > first_size
                values[1] +=  values[1]
                first_size += first_size

                # Datasets are still uneven, undersample
                second_size = first_size
            
            else
                values[1] +=  values[1][0..difference]
                first_size += difference
            end
=end
=begin
# Over sample
            difference = first_size - second_size
            if difference > second_size
                values[1] +=  values[1]
                second_size += second_size

                # Datasets are still uneven, undersample
                first_size = second_size
            else
                values[1] +=  values[1][0..difference]
                second_size += difference
                #difference -= second_size
            end
=end