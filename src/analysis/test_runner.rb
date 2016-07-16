
require 'json'

require 'fileutils'

PROJECT_LOOKUP = {'acra' =>  'ACRA',
'storm' =>  'apache',
'fresco' =>  'facebook',
'dagger' =>  'square',
'deeplearning4j' =>  'deeplearning4j',
'ion' =>  'koush',
'greenDAO' =>  'greenrobot',
'tempto' =>  'prestodb',
'blockly-android' =>  'google',
'spark' =>  'perwendel',
'governator' =>  'Netflix',
'cardslib' =>  'gabrielemariotti',
'ShowcaseView' =>  'amlcurran',
'parceler' =>  'johncarl81',
'mapstruct' =>  'mapstruct',
'jadx' =>  'skylot',
'nettosphere' =>  'Atmosphere',
'yardstick' =>  'gridgain',
'arquillian-core' =>  'arquillian',
'smile' =>  'haifengl',
'retrolambda' =>  'orfjackal',
'http-request' =>  'kevinsawicki',
'brave' =>  'openzipkin'
}

result = 'best'

method = 'svm'

experiment_number='4'

# Set value if projects need tobe skipped to skip to the project defined in the variable.
skip_to=nil

# read in dump of performances
# before the test write the performance to the measures/test_4/<method>/<project>/
    # based on whether it is best or worse record it
OUTPUT_RESULT="meaures/test_#{experiment_number}/#{method}"


#/"${method}"/"${REPO}"'


FILE_INPUT="weight_sum/#{result}_#{method}"

data = []

File.open(FILE_INPUT, 'r') do |file|
    data = JSON.parse(file.gets.chomp)
end

data.each do |project|

    if skip_to != nil
        # Skip projects until the desired project is found
        if project[0] == skip_to
            skip_to = nil
        end
    end

    if skip_to == nil
        FileUtils.mkdir_p("#{OUTPUT_RESULT}/#{project[0]}")

        # Output original result to file
        File.open("#{OUTPUT_RESULT}/#{project[0]}/data.csv", 'a') do |f|

            f.puts "#{result}, #{project[-3..-1].join(', ')}"
            puts "output: #{result}, #{project[-3..-1].join(', ')}"
        end

        # Output oversampling result
        owner = PROJECT_LOOKUP[project[0]]
        puts "Working on #{project[0]}"
        # Run over sampling version
        %x(bash model_tester 1 #{owner} #{project[0]} #{project[2]} #{project[3]} #{project[1].downcase} 1 #{result}-O)
    end
    #break
end

=begin
        header = ''
        if project[4] == 'test 1'
            header = project[3]
        elsif project[4] == 'test 3'
            header = project[2]
        else
            # Something went wrong  
        end
=end