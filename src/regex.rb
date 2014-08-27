###############################################################################
# Copyright (c) 2014 Jeremy S. Bradbury, Joseph Heron
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###############################################################################

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

PATCH_EXPR = /((@@)|-|\+| )?(.*?)[\n\r]/

PATCH_LINE_NUM_OLD = /-([0-9]+),([0-9]*)\s*\+([0-9]*),([0-9]*)/

PATCH_LINE_NUM = /-([0-9]+)(,([0-9]*))?\s*\+([0-9]*)(,([0-9]*))?/

NEWLINE_FIXER = /(\r?\n)|(\r)/

PACKAGE_PARSER = /(.*\/)(.*?\.java)/

TAG_REGEX = /refs\/tags\/(.*)/

PYTHON = 'py'

RUBY = 'rb'

JAVA = 'java'
