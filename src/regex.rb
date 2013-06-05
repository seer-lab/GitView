# The neccessary regular expressions for python multi-line comments
PYTHON_MULTI_LINE_FULL = /(.*?)(#.*)|(""".*""")/

PYTHON_MULTI_LINE_FIRST_HALF = /(""".*)/

PYTHON_MULTI_LINE_SECOND_HALF = /(.*""")/

JAVA_MULTI_LINE_FULL = /(.*?)(\/\/.*)|((\/\*.*\*\/)(.*))/

JAVA_MULTI_LINE_FIRST_HALF = /(\/\*.*)/

JAVA_MULTI_LINE_SECOND_HALF = /(.*\*\/)/

JAVA_CODE_TERMINATOR = /.*?}/

JAVA_CODE_LINE_BLOCK = /.*?{.*?}/

JAVA_CODE_BLOCK = /.*?{.*/

RUBY_MULTI_LIKE_FULL = /(.*?)(#.*)/

RUBY_MULTI_LINE_FIRST_HALF = /=being (.*)/

RUBY_MULTI_LINE_SECOND_HALF = /^=end/

REMOVE_QUOTE = /\".*?\"/

WHITE_SPACE = /^\s*$/

LINE_EXPR = /(.*?)\n/

PATCH_EXPR = /((@@)|-|\+|\s)?(.*?)\n/

PATCH_LINE_NUM = /-([0-9]+),([0-9]+)\s*\+([0-9]*),([0-9]*)/

PYTHON = 'py'

RUBY = 'rb'

JAVA = 'java'