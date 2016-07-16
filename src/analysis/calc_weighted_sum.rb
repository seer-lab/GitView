# What this needs:
=begin
exp_lists[i][0] = "project_name"
exp_lists[i][-3] = 'precision'
exp_lists[i][-2] = 'recall'
exp_lists[i][-1] = 'accuracy'
=end
# As long as exp_lists is ordered the same (aka the same order for each project for each list) then it will work

def calc_weighted_sum(exp_lists, weights=[0.5, 1.0, 0.5])
    results = Hash.new

    exp_lists.each do |list|


        list.each do |project|

            if results[project[0]] == nil
                results[project[0]] = Array.new
            end

            results[project[0]] << (project[-3].to_f * weights[0]) + (project[-2].to_f * weights[1]) + (project[-1].to_f * weights[2])
        end
    end
    return results
end

def find_sum(best=true)
    found = Hash.new
    i = 0
    results.each do |project, sum|

        if best
            found[project] = sum.each_with_index.max[1]
        else
            found[project] = sum.each_with_index.min[1]
        end
        puts "#{exp_lists[found[project]][i].join(' & ')}\\"
        i += 1
    end
end

# Path measures/rf/test_1/<project_name>/data.csv
#               test_3/...
TARGET_FOLDER='meaures'

full = '/home/joseph/source_code/GitView/src/analysis'

methods = ['rf', 'svm']
tests = ['test_1', 'test_3']

best = true

weights=[0.5, 1.0, 0.5]

found = Hash.new

project_data = Hash.new

tests.each do |test|
    found[test] = Hash.new
    methods.each do |method|
        found[test][method] = Hash.new
        Dir.glob("#{full}/#{TARGET_FOLDER}/#{test}/#{method}/*") do |file|

            project_name = File.basename(file)
            found[test][method][project_name] = {:best => -1, :worst => -1}

            if !project_data.has_key?(project_name)
                project_data[project_name] = Hash.new
            end

            if !project_data[project_name].has_key?(method)

                project_data[project_name][method] = {:best => Array.new, :best_info => Array.new, :worst => Array.new, :worst_info => Array.new }
            end

            lines = Array.new
            result = Array.new

            File.foreach("#{file}/data.csv") do |line|
                # header, precision, recall, accuracy
                lines << line.split(/,/)

                if lines[-1].size > 2
                    
                    lines[-1][0].strip!
                    lines[-1][1..-1] = lines[-1][1..-1].map do |v|
                        v.to_f
                    end

                    # Factor seperation distance in as a performance penalty (over optimized for one performance measure than the others)
                    #penalty = ((lines[-1][-3].to_f - lines[-1][-2].to_f).abs() * weights[0] + (lines[-1][-2].to_f - lines[-1][-1].to_f).abs() * weights[2] + (lines[-1][-3].to_f - lines[-1][-1].to_f).abs) / 3.0
                    #puts "penalty #{penalty}"

                    result << (lines[-1][-3].to_f * weights[0]) + (lines[-1][-2].to_f * weights[1]) + (lines[-1][-1].to_f * weights[2])# - penalty
                end
            end

            enum = result.each_with_index

            best_index = enum.max[1]
            found[test][method][project_name][:best] = {:sum => result[best_index], :header => lines[best_index][0], :line => lines[best_index]}
            project_data[project_name][method][:best] << found[test][method][project_name][:best][:sum]
            project_data[project_name][method][:best_info] << {:test => test, :method => method, :header => lines[best_index][0], :list => lines[best_index][1..-1]}

            worst_index = enum.min[1]
            found[test][method][project_name][:worst] = {:sum => result[worst_index], :header => lines[worst_index][0], :line => lines[worst_index]}
            project_data[project_name][method][:worst] << found[test][method][project_name][:worst][:sum]
            project_data[project_name][method][:worst_info] << {:test => test, :method => method, :header => lines[worst_index][0], :list => lines[best_index][1..-1]}

            i = 0
            result.each do |r|
                puts lines[i]
                puts r
                i+=1
            end                

            puts "project: #{project_name} #{found[test][method][project_name]}"
            #a = gets
        end
    end
end

def to_latex(project, index, entry, type=:best_info)

    swr = 0
    fs = 0

    puts "entry = #{entry[type]}"
    if entry[type][index][:test] == 'test_1'
        # param is swr
        swr = entry[type][index][:header]
        fs = 2
    else
        # param is fs #
        swr = 90
        fs = entry[type][index][:header]
    end

    list = entry[type][index][:list].map do |v|
        v.round(2)
    end.join(' & ')

    return "#{project} & #{entry[type][index][:method].upcase} & #{fs} & #{swr} & #{entry[type][index][:test].gsub(/_/, ' ')} & #{list} \\\\"
end

def to_a(project, index, entry, type=:best_info)

    swr = 0
    fs = 0

    if entry[type][index][:test] == 'test_1'
        # param is swr
        swr = entry[type][index][:header]
        fs = 2
    else
        # param is fs #
        swr = 90
        fs = entry[type][index][:header]
    end

    list = entry[type][index][:list].map do |v|
        v.round(2)
    end

    return [project, entry[type][index][:method].upcase, fs, swr, entry[type][index][:test].gsub(/_/, ' ')] + list
end

best_lists = {'rf' => Array.new, 'svm' => Array.new }

worst_lists = {'rf' => Array.new, 'svm' => Array.new }

project_data.each do |project, data|

        data.each do |method, value|

        #puts "Best:"
        #puts value[:best]


        index = value[:best].each_with_index.max[1]
        puts "Project: #{project}, best: #{index}"
        puts "actual value = #{value[:best_info][index]}, sum: #{value[:best][index]}"

        best_lists[method] << to_a(project, index, value, :best_info)


        #a = gets

        #puts "Worst:"
        #puts value[:worst]

        index = value[:worst].each_with_index.max[1]
        puts "Project: #{project}, worst: #{index}"
        puts "actual value = #{value[:worst_info][index]}, sum: #{value[:worst][index]}"

        worst_lists[method] << to_a(project, index, value, :worst_info)

        #a = gets
    end
end

best_lists.each do |key, best_list|
    best_lists[key] = best_list.sort_by do |x|
        x[0]
    end
    puts "BEST #{key}:"
    puts "#{best_lists[key]}"
end

worst_lists.each do |key, worst_list|
    worst_lists[key] = worst_list.sort_by do |x|
        x[0]
    end
    puts "WORST #{key}:"
    puts "#{worst_lists[key]}"
end

=begin
BEST:
acra & SVM & 2 & 80 & test 1 & 0.74 & 0.92 & 0.8 \\
arquillian-core & RF & 3 & 90 & test 3 & 0.53 & 0.98 & 0.55 \\
blockly-android & SVM & 2 & 60 & test 1 & 0.51 & 1.0 & 0.51 \\
brave & RF & 2 & 110 & test 1 & 0.59 & 0.97 & 0.65 \\
cardslib & SVM & 2 & 120 & test 1 & 0.5 & 1.0 & 0.5 \\
dagger & RF & 3 & 90 & test 3 & 0.5 & 1.0 & 0.5 \\
deeplearning4j & RF & 2 & 70 & test 1 & 0.55 & 0.96 & 0.58 \\
fresco & RF & 2 & 60 & test 1 & 0.52 & 1.0 & 0.53 \\
governator & RF & 2 & 60 & test 1 & 0.57 & 0.81 & 0.6 \\
greenDAO & SVM & 4 & 90 & test 3 & 0.5 & 1.0 & 0.5 \\
http-request & RF & 2 & 80 & test 1 & 0.87 & 0.79 & 0.84 \\
ion & RF & 2 & 90 & test 3 & 0.72 & 0.73 & 0.72 \\
jadx & SVM & 2 & 130 & test 1 & 0.55 & 0.82 & 0.58 \\
mapstruct & SVM & 2 & 70 & test 1 & 0.6 & 0.88 & 0.65 \\
nettosphere & RF & 2 & 110 & test 1 & 0.63 & 0.67 & 0.63 \\
parceler & SVM & 1 & 90 & test 3 & 0.57 & 0.92 & 0.61 \\
retrolambda & SVM & 2 & 130 & test 1 & 0.5 & 1.0 & 0.5 \\
ShowcaseView & SVM & 1 & 90 & test 3 & 0.73 & 0.89 & 0.78 \\
smile & SVM & 2 & 70 & test 1 & 0.5 & 1.0 & 0.5 \\
spark & SVM & 4 & 90 & test 3 & 0.5 & 1.0 & 0.5 \\
storm & RF & 2 & 60 & test 1 & 0.61 & 0.89 & 0.66 \\
tempto & RF & 2 & 120 & test 1 & 0.53 & 0.73 & 0.55 \\
yardstick & SVM & 2 & 70 & test 1 & 0.55 & 0.79 & 0.57 \\
WORST:
acra & SVM & 3 & 90 & test 3 & 0.71 & 0.86 & 0.75 \\
arquillian-core & RF & 4 & 90 & test 3 & 0.53 & 0.98 & 0.55 \\
blockly-android & SVM & 2 & 90 & test 1 & 0.51 & 1.0 & 0.51 \\
brave & RF & 4 & 90 & test 3 & 0.53 & 0.92 & 0.55 \\
cardslib & RF & 4 & 90 & test 3 & 0.53 & 0.68 & 0.54 \\
dagger & RF & 2 & 80 & test 1 & 0.68 & 0.76 & 0.7 \\
deeplearning4j & RF & 2 & 80 & test 1 & 0.55 & 0.96 & 0.58 \\
fresco & RF & 2 & 90 & test 3 & 0.5 & 1.0 & 0.5 \\
governator & RF & 2 & 90 & test 1 & 0.57 & 0.81 & 0.6 \\
greenDAO & SVM & 1 & 90 & test 3 & 0.5 & 1.0 & 0.5 \\
http-request & RF & 4 & 90 & test 3 & 0.77 & 0.63 & 0.72 \\
ion & RF & 1 & 90 & test 3 & 0.72 & 0.73 & 0.72 \\
jadx & RF & 2 & 70 & test 1 & 0.55 & 0.75 & 0.56 \\
mapstruct & RF & 5 & 90 & test 3 & 0.54 & 0.95 & 0.57 \\
nettosphere & SVM & 3 & 90 & test 3 & 0.56 & 0.64 & 0.57 \\
parceler & RF & 1 & 90 & test 3 & 0.68 & 0.7 & 0.69 \\
retrolambda & SVM & 4 & 90 & test 3 & 0.51 & 0.9 & 0.52 \\
ShowcaseView & RF & 2 & 90 & test 3 & 0.79 & 0.72 & 0.77 \\
smile & RF & 2 & 100 & test 1 & 0.5 & 0.97 & 0.49 \\
spark & RF & 2 & 80 & test 1 & 0.54 & 0.91 & 0.57 \\
storm & RF & 2 & 90 & test 1 & 0.61 & 0.89 & 0.66 \\
tempto & RF & 2 & 130 & test 1 & 0.53 & 0.73 & 0.55 \\
yardstick & SVM & 2 & 100 & test 1 & 0.55 & 0.79 & 0.57 \\
=end

=begin
BEST rf:
acra & RF & 2 & 60 & test 1 & 0.68 & 0.95 & 0.75 \\
arquillian-core & RF & 3 & 90 & test 3 & 0.53 & 0.98 & 0.55 \\
blockly-android & RF & 2 & 90 & test 3 & 0.56 & 0.73 & 0.58 \\
brave & RF & 2 & 110 & test 1 & 0.59 & 0.97 & 0.65 \\
cardslib & RF & 2 & 100 & test 1 & 0.65 & 0.74 & 0.67 \\
dagger & RF & 3 & 90 & test 3 & 0.5 & 1.0 & 0.5 \\
deeplearning4j & RF & 2 & 70 & test 1 & 0.55 & 0.96 & 0.58 \\
fresco & RF & 2 & 60 & test 1 & 0.52 & 1.0 & 0.53 \\
governator & RF & 2 & 60 & test 1 & 0.57 & 0.81 & 0.6 \\
greenDAO & RF & 2 & 60 & test 1 & 0.51 & 0.74 & 0.51 \\
http-request & RF & 2 & 80 & test 1 & 0.87 & 0.79 & 0.84 \\
ion & RF & 2 & 90 & test 3 & 0.72 & 0.73 & 0.72 \\
jadx & RF & 2 & 130 & test 1 & 0.55 & 0.75 & 0.56 \\
mapstruct & RF & 1 & 90 & test 3 & 0.54 & 0.95 & 0.57 \\
nettosphere & RF & 2 & 110 & test 1 & 0.63 & 0.67 & 0.63 \\
parceler & RF & 3 & 90 & test 3 & 0.68 & 0.7 & 0.69 \\
retrolambda & RF & 2 & 120 & test 1 & 0.52 & 0.79 & 0.54 \\
ShowcaseView & RF & 2 & 130 & test 1 & 0.78 & 0.83 & 0.8 \\
smile & RF & 5 & 90 & test 3 & 0.5 & 0.98 & 0.5 \\
spark & RF & 2 & 110 & test 1 & 0.54 & 0.91 & 0.57 \\
storm & RF & 2 & 60 & test 1 & 0.61 & 0.89 & 0.66 \\
tempto & RF & 2 & 120 & test 1 & 0.53 & 0.73 & 0.55 \\
yardstick & RF & 2 & 70 & test 1 & 0.54 & 0.67 & 0.55 \\
BEST svm:
acra & SVM & 2 & 80 & test 1 & 0.74 & 0.92 & 0.8 \\
arquillian-core & SVM & 4 & 90 & test 3 & 0.55 & 0.83 & 0.57 \\
blockly-android & SVM & 2 & 60 & test 1 & 0.51 & 1.0 & 0.51 \\
brave & SVM & 2 & 130 & test 1 & 0.5 & 1.0 & 0.5 \\
cardslib & SVM & 2 & 120 & test 1 & 0.5 & 1.0 & 0.5 \\
dagger & SVM & 5 & 90 & test 3 & 0.5 & 0.95 & 0.49 \\
deeplearning4j & SVM & 3 & 90 & test 3 & 0.61 & 0.84 & 0.65 \\
fresco & SVM & 3 & 90 & test 3 & 0.5 & 0.99 & 0.5 \\
governator & SVM & 1 & 90 & test 3 & 0.65 & 0.57 & 0.63 \\
greenDAO & SVM & 4 & 90 & test 3 & 0.5 & 1.0 & 0.5 \\
http-request & SVM & 2 & 80 & test 1 & 0.59 & 0.93 & 0.65 \\
ion & SVM & 5 & 90 & test 3 & 0.58 & 0.83 & 0.61 \\
jadx & SVM & 2 & 130 & test 1 & 0.55 & 0.82 & 0.58 \\
mapstruct & SVM & 2 & 70 & test 1 & 0.6 & 0.88 & 0.65 \\
nettosphere & SVM & 2 & 120 & test 1 & 0.49 & 0.77 & 0.49 \\
parceler & SVM & 1 & 90 & test 3 & 0.57 & 0.92 & 0.61 \\
retrolambda & SVM & 2 & 130 & test 1 & 0.5 & 1.0 & 0.5 \\
ShowcaseView & SVM & 1 & 90 & test 3 & 0.73 & 0.89 & 0.78 \\
smile & SVM & 2 & 70 & test 1 & 0.5 & 1.0 & 0.5 \\
spark & SVM & 4 & 90 & test 3 & 0.5 & 1.0 & 0.5 \\
storm & SVM & 2 & 100 & test 1 & 0.51 & 0.7 & 0.52 \\
tempto & SVM & 2 & 120 & test 1 & 0.66 & 0.5 & 0.62 \\
yardstick & SVM & 2 & 70 & test 1 & 0.55 & 0.79 & 0.57 \\
WORST rf:
acra & RF & 5 & 90 & test 3 & 0.77 & 0.78 & 0.77 \\
arquillian-core & RF & 4 & 90 & test 3 & 0.53 & 0.98 & 0.55 \\
blockly-android & RF & 1 & 90 & test 3 & 0.56 & 0.73 & 0.58 \\
brave & RF & 4 & 90 & test 3 & 0.53 & 0.92 & 0.55 \\
cardslib & RF & 4 & 90 & test 3 & 0.53 & 0.68 & 0.54 \\
dagger & RF & 2 & 80 & test 1 & 0.68 & 0.76 & 0.7 \\
deeplearning4j & RF & 2 & 80 & test 1 & 0.55 & 0.96 & 0.58 \\
fresco & RF & 2 & 90 & test 3 & 0.5 & 1.0 & 0.5 \\
governator & RF & 2 & 90 & test 1 & 0.57 & 0.81 & 0.6 \\
greenDAO & RF & 2 & 100 & test 1 & 0.51 & 0.74 & 0.51 \\
http-request & RF & 4 & 90 & test 3 & 0.77 & 0.63 & 0.72 \\
ion & RF & 1 & 90 & test 3 & 0.72 & 0.73 & 0.72 \\
jadx & RF & 2 & 70 & test 1 & 0.55 & 0.75 & 0.56 \\
mapstruct & RF & 5 & 90 & test 3 & 0.54 & 0.95 & 0.57 \\
nettosphere & RF & 2 & 90 & test 3 & 0.85 & 0.38 & 0.66 \\
parceler & RF & 1 & 90 & test 3 & 0.68 & 0.7 & 0.69 \\
retrolambda & RF & 2 & 90 & test 1 & 0.52 & 0.79 & 0.54 \\
ShowcaseView & RF & 2 & 90 & test 3 & 0.79 & 0.72 & 0.77 \\
smile & RF & 2 & 100 & test 1 & 0.5 & 0.97 & 0.49 \\
spark & RF & 2 & 80 & test 1 & 0.54 & 0.91 & 0.57 \\
storm & RF & 2 & 90 & test 1 & 0.61 & 0.89 & 0.66 \\
tempto & RF & 2 & 130 & test 1 & 0.53 & 0.73 & 0.55 \\
yardstick & RF & 2 & 60 & test 1 & 0.54 & 0.67 & 0.55 \\
WORST svm:
acra & SVM & 3 & 90 & test 3 & 0.71 & 0.86 & 0.75 \\
arquillian-core & SVM & 2 & 90 & test 3 & 0.55 & 0.83 & 0.57 \\
blockly-android & SVM & 2 & 90 & test 1 & 0.51 & 1.0 & 0.51 \\
brave & SVM & 3 & 90 & test 3 & 0.49 & 0.62 & 0.49 \\
cardslib & SVM & 4 & 90 & test 3 & 0.51 & 0.88 & 0.52 \\
dagger & SVM & 2 & 70 & test 1 & 0.5 & 0.94 & 0.5 \\
deeplearning4j & SVM & 2 & 130 & test 1 & 0.49 & 0.83 & 0.49 \\
fresco & SVM & 2 & 90 & test 3 & 0.5 & 0.99 & 0.5 \\
governator & SVM & 3 & 90 & test 3 & 0.65 & 0.57 & 0.63 \\
greenDAO & SVM & 1 & 90 & test 3 & 0.5 & 1.0 & 0.5 \\
http-request & SVM & 3 & 90 & test 3 & 0.66 & 0.7 & 0.67 \\
ion & SVM & 2 & 90 & test 3 & 0.58 & 0.83 & 0.61 \\
jadx & SVM & 2 & 100 & test 1 & 0.55 & 0.82 & 0.58 \\
mapstruct & SVM & 1 & 90 & test 3 & 0.57 & 0.9 & 0.61 \\
nettosphere & SVM & 3 & 90 & test 3 & 0.56 & 0.64 & 0.57 \\
parceler & SVM & 2 & 90 & test 3 & 0.57 & 0.92 & 0.61 \\
retrolambda & SVM & 4 & 90 & test 3 & 0.51 & 0.9 & 0.52 \\
ShowcaseView & SVM & 2 & 80 & test 1 & 0.6 & 0.99 & 0.66 \\
smile & SVM & 2 & 90 & test 3 & 0.53 & 0.96 & 0.55 \\
spark & SVM & 3 & 90 & test 3 & 0.5 & 1.0 & 0.5 \\
storm & SVM & 2 & 110 & test 1 & 0.51 & 0.7 & 0.52 \\
tempto & SVM & 2 & 130 & test 1 & 0.66 & 0.5 & 0.62 \\
yardstick & SVM & 2 & 100 & test 1 & 0.55 & 0.79 & 0.57 \\
=end

