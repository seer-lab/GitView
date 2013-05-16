gem 'json', '~> 1.7.7'
require 'github_api'
require 'nokogiri'
require 'open-uri'

#Github.repos.list user: 'dataBaseError'

password = ''












































#\\n([+-][\w\s\.*;\/]*)
#\\n[+-]([^(\\)]*)


github = Github.new do | config |
	config.auto_pagination = true
	config.mime_type = :full 
	config.login = 'dataBaseError'
	config.password = password
end

a = github.repos.commits.all 'tinfoilhat', 'tinfoil-sms'

puts a.length

response = github.repos.commits.get_request(a.body[0]["url"])

file = doc = Nokogiri::HTML(open(response.body["files"][0]["raw_url"]))



#a = Github.repos.commits.all 'tinfoilhat', 'tinfoil-sms'

#puts a.length

#peter-murach / github
#github.git_data.tags.get 'peter-murach', 'github', 'cadf5847a03f9fb3ca7e99ca355f27c340c3f8bc'

github.repos.tags 'peter-murach', 'github'
