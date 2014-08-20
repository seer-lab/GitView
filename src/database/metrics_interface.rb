require 'mysql'

module Metrics_database
    require_relative 'database_utility'

    DATABASE = 'metrics'
    HOST = 'localhost'
    USERNAME = 'git_miner'
    PASSWORD = 'pickaxe'

    #Tables
    REPO = 'repositories'
    COMMITS = 'commits'
    METHOD = 'method'
    CLASS = 'class'
    PACKAGE = 'package'

    # Column Names
    # Repo
    REPO_ID = 'repo_id'
    REPO_NAME = 'repo_name'
    REPO_OWNER = 'repo_owner'

    # Commits
    COMMIT_ID = 'commit_id'
    REPO_REFERENCE = 'repo_reference'
    PROJECT_NAME = 'project_name'
    DATE = 'commit_date'
    SHA = 'sha_hash'

    # Method
    COMMIT_REFERENCE = 'commit_reference'
    METHOD_NAME = 'method_name'
    NUMBER_METHOD_LINE = 'number_method_line'
    NESTED_BLOCK_DEPTH = 'nested_block_depth'
    CYCLOMATIC_COMPLEXITY = 'cyclomatic_complexity'
    NUMBER_PARAMETERS = 'number_parameters'

    # Class 
    CLASS_ID = 'class_id'
    CLASS_NAME = 'class_name'
    INHERITANCE_DEPTH = 'inheritance_depth'
    WEIGHTED_METHODS = 'weighted_methods'
    CHILDREN_COUNT = 'children_count'
    OVERRIDDEN_METHODS = 'overridden_methods'
    LACK_COHESION_METHODS = 'lack_cohesion_methods'
    ATTRIBUTE_COUNT = 'attribute_count'
    STATIC_ATTRIBUTE_COUNT = 'static_attribute_count'
    METHOD_COUNT = 'method_count'
    STATIC_METHOD_COUNT = 'static_method_count'
    SPECIALIZATION_INDEX = 'specialization_index'

    # Package
    PACKAGE_ID = 'package_id'
    PACKAGE_NAME = 'package_name'
    AFFERENT_COUPLING = 'afferent_coupling'
    EFFERENT_COUPLING = 'efferent_coupling'
    INSTABILITY = 'instability'
    ABSTRACTNESS = 'abstractness'
    NORMALIZED_DISTANCE = 'normalized_distance'
    CLASSES_NUMBER = 'classes_number'
    INTERFACES_NUMBER = 'interfaces_number'

    def Metrics_database.createConnection()
        Mysql.new(HOST, USERNAME, PASSWORD, DATABASE)
    end

    # Get all the repositories stored in the database
    # Params:
    # +con+:: the database connection used. 
    def Metrics_database.getRepos(con)
        pick = con.prepare("SELECT * FROM #{REPO}")
        pick.execute

        return DatabaseUtility.fetch_results(pick)
    end

    # Get the repo id if the given repository or nil if it does not exist.
    # Params:
    # +con+:: the database connection used. 
    # +repo+:: the name of the repository
    # +owner+:: the owner of the repository
    def Metrics_database.getRepoExist(con, repo, owner)
        pick = con.prepare("SELECT #{REPO_ID} FROM #{REPO} WHERE #{REPO_NAME} LIKE ? AND #{REPO_OWNER} LIKE ?")
        pick.execute(repo, owner)

        result = pick.fetch

        #There should be only 1 id return anyways.
        return DatabaseUtility.toInteger(result)
    end 

    # Insert the given repository to the database
    # +con+:: the database connection used. 
    # +repo+:: the name of the repository
    def Metrics_database.insertRepo(con, repo, owner)
        pick = con.prepare("INSERT INTO #{REPO} (#{REPO_NAME}, #{REPO_OWNER}) VALUES (?, ?)")
        pick.execute(repo, owner)

        return DatabaseUtility.toInteger(pick.insert_id)
    end

    # Get all the commits stored in the database
    # Params:
    # +con+:: the database connection used. 
    def Metrics_database.getCommits(con)
        pick = con.prepare("SELECT * FROM #{COMMITS}")
        pick.execute

        return DatabaseUtility.fetch_results(pick)
    end

    def Metrics_database.getCommitExist(con, sha_hash)

        pick = con.prepare("SELECT #{COMMIT_ID} FROM #{COMMITS} WHERE #{SHA} = ?")
        pick.execute(sha_hash)

        result = pick.fetch

        return DatabaseUtility.toInteger(result)
    end

    # Insert the given commits to the database
    # +con+:: the database connection used. 
    # +repo_reference+:: the repository reference
    # +sha_hash+:: the sha hash
    # +commit_date+
    def Metrics_database.insertCommits(con, repo_reference, project_name, sha_hash, commit_date)

        pick = con.prepare("INSERT INTO #{COMMITS} (#{REPO_REFERENCE}, #{SHA}, #{DATE}, #{PROJECT_NAME}) VALUES (?, ?, ?, ?)")
        pick.execute(repo_reference, sha_hash, commit_date, project_name)

        return DatabaseUtility.toInteger(pick.insert_id)
    end

    def Metrics_database.getMethods(con)
        pick = con.prepare("SELECT * FROM #{METHOD}")
        pick.execute

        return DatabaseUtility.fetch_results(pick)
    end

    def Metrics_database.insertMethod(con, commit_reference, name_method, number_method_line, nested_block_depth, cyclomatic_complexity, number_parameters)
        
        pick = con.prepare("INSERT INTO #{METHOD} (#{COMMIT_REFERENCE}, #{METHOD_NAME}, #{NUMBER_METHOD_LINE}, #{NESTED_BLOCK_DEPTH}, #{CYCLOMATIC_COMPLEXITY}, #{NUMBER_PARAMETERS}) VALUES (?, ?, ?, ?, ?, ?)")
        pick.execute(commit_reference, name_method, number_method_line.to_i, nested_block_depth.to_i, cyclomatic_complexity.to_i, number_parameters.to_i)

        return DatabaseUtility.toInteger(pick.insert_id)
    end

    def Metrics_database.getClass(con)
        pick = con.prepare("SELECT * FROM #{CLASS}")
        pick.execute

        return DatabaseUtility.fetch_results(pick)
    end

    def Metrics_database.insertClass(con, commit_reference, class_name,  overridden_methods, attribute_count, children_count, method_count, inheritance_depth, lack_cohesion_method, specialization_index, static_method_count, weighted_methods,static_attribute_count)

        pick = con.prepare("INSERT INTO #{CLASS} (#{COMMIT_REFERENCE}, #{CLASS_NAME}, #{INHERITANCE_DEPTH}, #{WEIGHTED_METHODS}, #{CHILDREN_COUNT}, #{OVERRIDDEN_METHODS}, #{LACK_COHESION_METHODS}, #{ATTRIBUTE_COUNT}, #{STATIC_ATTRIBUTE_COUNT}, #{METHOD_COUNT}, #{STATIC_METHOD_COUNT}, #{SPECIALIZATION_INDEX}) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")

        pick.execute(commit_reference, class_name, inheritance_depth.to_i, weighted_methods.to_i, children_count.to_i, overridden_methods.to_i, lack_cohesion_method.to_f, attribute_count.to_i, static_attribute_count.to_i, method_count.to_i, static_method_count.to_i, specialization_index.to_f)

        return DatabaseUtility.toInteger(pick.insert_id)
    end

    def Metrics_database.getPackage(con)
        pick = con.prepare("SELECT * FROM #{PACKAGE}")
        pick.execute

        return DatabaseUtility.fetch_results(pick)
    end

    def Metrics_database.insertPackage(con, commit_reference, package_name, classes_number, afferent_coupling, interfaces_number, instability, efferent_coupling, abstractness, normalized_distance)    

        pick = con.prepare("INSERT INTO #{PACKAGE} (#{COMMIT_REFERENCE}, #{PACKAGE_NAME}, #{AFFERENT_COUPLING}, #{EFFERENT_COUPLING}, #{INSTABILITY}, #{ABSTRACTNESS}, #{NORMALIZED_DISTANCE}, #{CLASSES_NUMBER}, #{INTERFACES_NUMBER}) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")

        pick.execute(commit_reference, package_name, afferent_coupling.to_i, efferent_coupling.to_i, instability.to_f, abstractness.to_f, normalized_distance.to_f, classes_number.to_i, interfaces_number.to_i)

        return DatabaseUtility.toInteger(pick.insert_id)
    end
end