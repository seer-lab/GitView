require 'pg'

class DBinterface

    USERNAME = "postgres"
    PASSWORD = "password"

    # Default port
    PORT = '5434' #'5432'

    OPENING_TIME = '8:00:00'
    CLOSING_TIME = '23:00:00'

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

    def get_date_range(repo_owner, repo_name)

        att_names = ['quarter_0', 'quarter_1', 'quarter_2', 'quarter_3', 'quarter_4']

        query = "select
                    v.min_date as quarter_0,
                    v.min_date+v.quarter as quarter_1,
                    v.min_date+(v.quarter*2) as quarter_2,
                    v.min_date+(v.quarter*3) as quarter_3,
                    v.max_date as quarter_4
                from (
                    select
                        min(c.commit_date) as min_date,
                        max(c.commit_date) as max_date,
                        (max(c.commit_date) - min(c.commit_date))/4 as quarter
                    from
                        repositories as r INNER JOIN
                        commits as c ON r.repo_id = c.repo_reference
                    where
                        r.repo_name = $1 AND
                        r.repo_owner = $2
                    ) as v"

        i = 0
        values = Array.new

        params = create_params([repo_name, repo_owner])

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

    def get_svm_data(repo_owner, repo_name, start_date, end_date, limit)

        att_names = ['commit_id', 'name', 'method_info_id', 'signature', 'no_change', 'add_change', 'delete_change', 'modify_change', 'committer', 'change_frequency', 'previous_change_type', 'has_next']

        query = "select 
            v.commit_id,
            v.name,
            v.method_info_id,
            v.signature,   
            v.no_change,
            v.add_change,
            v.delete_change,
            v.modify_change,
            v.committer,
            v.change_frequency,
            v.previous_change_type,
            v.has_next
        from
            (select
                c.commit_id,
                f.name,
                mi.method_info_id,
                mi.signature,   
                CASE mi.change_type WHEN 0 THEN 1 ELSE -1 END As no_change,
                CASE mi.change_type WHEN 1 THEN 1 ELSE -1 END as add_change,
                CASE mi.change_type WHEN 2 THEN 1 ELSE -1 END as delete_change,
                CASE mi.change_type WHEN 3 THEN 1 ELSE -1 END as modify_change,
                c.commit_date,
                com.name as committer,
                exists_in_commits(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) / pcc.previous_commit_count::float as change_frequency,
                previous_change_type(c.repo_reference, c.commit_date, f.path, f.name, mi.signature),
                has_next_commit(c.repo_reference, c.commit_date, f.path, f.name, mi.signature) as has_next
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
            v.has_next = $5 AND
            v.commit_date > $3 AND
            v.commit_date < $4
        order by
            random()
        limit $6"

        values = Array.new

        i = 0
        2.times do |category|
            
            params = create_params([repo_name, repo_owner, start_date, end_date, category, limit/2])
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
        end

        return values
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