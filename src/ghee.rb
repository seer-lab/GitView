require 'ghee'

gh = Ghee.basic_auth("dataBaseError","")

















a = 1
i = 1
while i < 6
	a = gh.repos("tinfoilhat", "tinfoil-sms").commits.paginate(:per_page => 100, :page => i)
	puts a
	puts "page length = #{a.length} and page number #{i}"
	i = i + 1
end


#gh.repos("tinfoilhat", "tinfoil-sms").issues.paginate(:per_page => 100, :page => 1)[0] == gh.repos("tinfoilhat", "tinfoil-sms").commits.paginate(:per_page => 100, :page => 2)[0]


#gh.repos("raspberrypi","linux").issues.all
=begin
a = gh.repos("tinfoilhat", "tinfoil-sms").commits.paginate(:per_page => 100, :page => 1)
puts a.length

a = gh.repos("tinfoilhat", "tinfoil-sms").commits.all
puts a.length

b = gh.repos("tinfoilhat", "tinfoil-sms").commits({
  :sha => "master" # optional
})
puts b.length

# 7 Commits
a = gh.repos("tinfoilhat", "test").commits.all

#72 commits
a = gh.repos("gnu-user", "algorithms-project").commits.all

#around 92
a = gh.repos("creaktive", "rainbarf").commits.all

# around 125 commits
a = gh.repos("swanson", "stringer").commits.all

a = gh.repos("gnu-user", "guidoless-python").commits.all
=end

#a = gh.repos("swanson", "stringer").commits.paginate(:per_page => 100, :page => 1).next_page
