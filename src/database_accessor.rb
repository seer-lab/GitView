require_relative 'database_interface'

#The expression to match the given extention
EXTENTION_EXPRESSION = '%\.'

PYTHON = 'py'

def getFiles(con, extention)
    pick = con.prepare("SELECT #{FILE} FROM #{FILE} WHERE #{NAME} LIKE ?")
    pick.execute("#{EXTENTION_EXPRESSION}#{extention}")

    rows = pick.num_rows
    results = Array.new(rows)

    rows.times do |x|
        results[x] = pick.fetch
    end

    return results
end

con = createConnection()

#Get the first line of documentation
files = getFiles(con, PYTHON)

#Pythonic comment regular expression
comments = files[0][0].scan(/(#(.*)\n)|("""(.*)"""\n)/)

comments.each { |comment|
    #Since there is 4 selection groups check if the second one is valid
    if comment[1] != nil
        puts comment[1]
    #If the second selction is not valid the 3 one is the next choice
    elsif comment[3] != nil
        puts comment[3]
    end
}


