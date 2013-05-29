# The neccessary regular expressions for python multi-line comments
PYTHON_MULTI_LINE_FULL = /(.*?)(#.*)|(""".*""")/

PYTHON_MULTI_LINE_FIRST_HALF = /(""".*)/

PYTHON_MULTI_LINE_SECOND_HALF = /(.*""")/

JAVA_MULTI_LINE_FULL = /(.*?)(\/\/.*)|((\/\*.*\*\/)(.*))/

JAVA_MULTI_LINE_FIRST_HALF = /(\/\*.*)/

JAVA_MULTI_LINE_SECOND_HALF = /(.*\*\/)/

RUBY_MULTI_LIKE_FULL = /(.*?)(#.*)/

RUBY_MULTI_LINE_FIRST_HALF = /=being (.*)/

RUBY_MULTI_LINE_SECOND_HALF = /^=end/

WHITE_SPACE = /^\s*$/

LINE_EXPR = /(.*?)\n/

PYTHON = 'py'

RUBY = 'rb'

JAVA = 'java'