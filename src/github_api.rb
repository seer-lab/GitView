gem 'json', '~> 1.7.7'
require 'github_api'
require 'nokogiri'
require 'open-uri'


class Rate
	def initialize(github)
		getRateRemaining(github)
		@timeStart = Time.now
		@limit = false
	end

	def decreaseRate(amount)
		if @rateRemaining < amount
			@limit = true
			return false
		end
		@rateRemaining = @rateRemaining - amount
		
		return true
	end

	def getRateRemaining(github)
		@rateRemaining = github.ratelimit_remaining
	end

	def checkRate(github)
		getRateRemaining(github)
		return @rateRemaining
	end

	def rate()
		@rateRemaining
	end
end

#Github.repos.list user: 'dataBaseError'
puts "Password"
password = gets.chomp

#\\n([+-][\w\s\.*;\/]*)
#\\n[+-]([^(\\)]*)


github = Github.new do | config |
    config.auto_pagination = true
    config.mime_type = :full 
    config.login = 'dataBaseError'
    config.password = password
end


rate = Rate.new(github)

puts rate.rate()

a = github.repos.commits.all 'tinfoilhat', 'tinfoil-sms'

puts rate.checkRate(github)
#puts a.length

commitFile = File.new("test.log", "w")
	a.each { |x|  commitFile.puts x }
commitFile.close

#response = github.repos.commits.get_request(a.body[0]["url"])

#file = Nokogiri::HTML(open(response.body["files"][0]["raw_url"]))



#a = Github.repos.commits.all 'tinfoilhat', 'tinfoil-sms'

#puts a.length

#peter-murach / github
#github.git_data.tags.get 'peter-murach', 'github', 'cadf5847a03f9fb3ca7e99ca355f27c340c3f8bc'

#github.repos.tags 'peter-murach', 'github'
