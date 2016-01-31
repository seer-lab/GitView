require 'libsvm'

require 'ruby-fann'

class SVM_Predictor

	def initialize(cache_size=1, eps=0.001, c=10)
		@problem = Libsvm::Problem.new
		@parameter = Libsvm::SvmParameter.new

		@parameter.cache_size = cache_size # in megabytes

		@parameter.eps = eps
		@parameter.c = c
	end

	def train(input, output)
		examples = input.map {|ary| Libsvm::Node.features(ary) }
		@problem.set_examples(output, examples)

		@model = Libsvm::Model.train(@problem, @parameter)
	end

	def test(input)

		return @model.predict(Libsvm::Node.features(input))
	end
end

class FANN_Predictor

	def initialize(number_inputs=3, hidden_neurons=[4], num_outputs=1, max_epochs=1000, errors=10, mse=0.1)

		@fann = RubyFann::Standard.new(:num_inputs=>number_inputs, :hidden_neurons=>hidden_neurons, :num_outputs=>num_outputs)
		@max_epochs = max_epochs
		@errors = errors
		@mse = mse
	end

	def train(input, output)
		puts "input = #{input.first.size}, output = #{output.size}"

		# Output is a 1d array need it to be 2d aka
		output.map! do |value|
			[value]
		end

		train = RubyFann::TrainData.new(:inputs=>input, :desired_outputs=>output)

		@fann.train_on_data(train, @max_epochs, @errors, @mse) # 1000 max_epochs, 10 errors between reports and 0.1 desired MSE (mean-squared-error)

	end

	def test(input)

		return @fann.run(input)[0]
	end

end

=begin
input.map! do |vector|
	vector.map do |value|
		value.to_f
	end
end

input.each_with_index do |vector, index|
	puts "vector = #{vector}, out = #{output[index]}"
end
=end
