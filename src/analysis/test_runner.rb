
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

method = 'rf'

experiment_number='10'

# read in dump of performances
# before the test write the performance to the measures/test_4/<method>/<project>/
    # based on whether it is best or worse record it
OUTPUT_RESULT="meaures/test_#{experiment_number}/#{method}"


#/"${method}"/"${REPO}"'


FILE_INPUT="/home/joseph/source_code/GitView/src/analysis/weight_sum/#{result}_#{method}"

data = []

File.open(FILE_INPUT, 'r') do |file|
    data = JSON.parse(file.gets.chomp)
end

data.each do |project|

    FileUtils.mkdir_p("#{OUTPUT_RESULT}/#{project[0]}")

    # Output original result to file
    File.open("#{OUTPUT_RESULT}/#{project[0]}/data.csv", 'w+') do |f|

        f.puts "#{result}, #{project[-3..-1].join(', ')}"
    end

    # Output oversampling result
    owner = PROJECT_LOOKUP[project[0]]
    # Run over sampling version
    %x(bash /home/joseph/source_code/GitView/src/analysis/model_tester 1 #{owner} #{project[0]} #{project[2]} #{project[3]} #{project[1].downcase} 1 #{result}-O)
    break
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