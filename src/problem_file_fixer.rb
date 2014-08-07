require_relative 'database/database_interface'
require_relative 'regex'
require_relative 'database/stats_db_interface'

gem 'github_api', '=0.9.7'
require 'github_api'

username = "dataBaseError"
password = gets.chomp

github = Github.new do | config |
    config.auto_pagination = true
    config.mime_type = :full 
    config.login = username
    config.password = password
end

con = Github_database.createConnection()