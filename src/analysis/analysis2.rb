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

# Install graphviz and the gem ruby-graphviz
require 'graphviz'
require 'date'

require_relative '../database/stats_db_interface'

require_relative '../progress/progress'


class Graph

    #CHANGE_LIST = {:co_change => 'co_change', :version => 'version'}

    def initialize(directed=false)
        @graph = Hash.new # {node1 => {edge1 => weight1, edge2 => weight2}, node2 => ...} Where edge1 is a node
        @directed = directed
    end

    def add_vertex(vertex)
        if !has_vertex?(vertex)
            @graph[vertex] = Hash.new
        end
    end

    def add_edge(vertex_one, vertex_two, weight=nil)
        
        # Ensure both vertex are already in the graph
        add_vertex(vertex_one)
        add_vertex(vertex_two)

        # Added the new edges
        push_edge(vertex_one, vertex_two, weight)

        if !@directed 
            push_edge(vertex_two, vertex_one, weight)
        end
    end

    def has_vertex?(vertex)
        return @graph.has_key?(vertex)
    end

    def has_edge?(vertex_one, vertex_two)
        return @graph[vertex_one].has_key?(vertex_two)
    end

    def push_edge(vertex_one, vertex_two, weight)
        @graph[vertex_one][vertex_two] = weight
    end

    def remove_edge(vertex_one, vertex_two)
        @graph[vertex_one].delete(vertex_two)
    end

    def remove_vertex(vertex)

        if !@directed
            # Go through edges and delete both connections
            @graph[vertex].keys.each do |v|
                @graph[v].delete(vertex)
            end
        else
            # Go through all vertexes and delete the vertex connections that are found
            @graph.keys.each do |v|
                @graph[v].delete(vertex)
            end
        end

        @graph.delete(vertex)

    end

    def each
        @graph.each do |node, edge|
            yield [node, edge]
        end
    end

    def to_dot(w=nil)
        dot_form = "graph g {\n"

        @graph.each do |vertex, edges|
            if edges
                edges.each do |to, weight|

                    if w
                        if w == weight
                            dot_form += edge_to_dot(vertex.method_id, to.method_id, weight)
                        end
                    else
                        dot_form += edge_to_dot(vertex.method_id, to.method_id, weight)
                    end
                end
            else
                dot_form += node_to_dot(vertex['method_id'])
            end
        end

        dot_form += "}"

        return dot_form
    end

private :push_edge

    def node_to_dot(node)
        return "#{node.to_s};\n"
    end

    def edge_to_dot(node1, node2, weight=nil)
        result = "#{node1.to_s} #{get_edge} #{node2.to_s}"
        if weight
            result += " [label = #{weight}]"
        end
        return "#{result};\n"
    end
    
    def get_edge
        if @directed
            return '->'
        end
        return '--'
    end
end

class MethodNode

    attr_accessor :commit_id, :sha, :method_id, :path, :name, :signature, :commit_date

    def initialize(commit_id, sha, method_id, path, name, signature, commit_date)
        @commit_id = commit_id
        @sha = sha
        @method_id = method_id
        @path = path
        @name = name
        @signature = signature
    end

    def identifier
        return method_id
    end

    def ==(other)
        return class_check(other) && @commit_id == other.commit_id && @method_id == other.method_id
    end

    def change_version(other)
        return class_check(other) && self != other && path == other.path && name == other.name && signature == other.signature
    end

    def eql?(other)
        return self == other
    end

    def hash
        return identifier
    end

    def to_s
        return "#{commit_id}, #{method_id}, #{path}#{name}, #{signature}"
    end

    def method_uuid
        "#{path}#{name}##{signature}"
    end

    def class_check(other)
        return self.class == other.class
    end

    private :class_check
end

def add_element(element=nil)
    if element == nil
        element = "-"
    end

    return "#{element}"
end

def pretty_print(graph, spacing_list)

    node_string = "_______|commits\n"
    node_string += "methods|\n"
    yield node_string
    node_string = ""
    prev_node = nil

    graph.each do |node, edges|

        if prev_node && node.change_version(prev_node)
            # Do nothing
        else
            if node.method_uuid.length > 10
                node_string += node.method_uuid[0..10]
            else
                node_string += node.method_uuid
                node_string += " " * (10 - node.method_uuid.size)
            end
            prev_offset = 0
            cur_offset = 0
            row = ""
            edges.each do |date|
                # Since the dates are ordered we just have to go through and use the offset - prev_offset
                offset = spacing_list[date.to_s]
                cur_offset = offset - prev_offset - 1
                #if row.size > spacing_list.size 
                #    yield "date = #{date.to_s}, offset #{offset}, prev_offset #{prev_offset}, cur_offset #{cur_offset}, rowsize = #{row.size} "
                #    yield edges.to_s
                #end


                cur_offset.times do |x|
                    row += add_element
                end

                row += add_element("*")
                
                prev_offset = offset
            end
            if spacing_list.size > row.size
                #puts "Amount = #{spacing_list.to_a[-1][-1]}, #{row.size}"#, #{edges.size}, #{cur_offset}"
                #puts "adding #{spacing_list.to_a[-1][-1] - row.size}"
                row += "-" * (spacing_list.to_a[-1][-1] - row.size)
                #puts "total_length #{row.size}"
            end
            node_string += "#{row}\n"
            yield node_string
            node_string = ""
        end
    end
    #return node_string
end

#b = MethodNode.new(1323, 'dfasdf24fvaefama', 42, 'CrashReport/sample/org/acra/sampleapp/', 'CrashTest.java', '@Override public String getFormId() {')

$high_threshold = 0.5
$ONE_TO_MANY = true
$low_threshold, $size_threshold = 0.8, 20

repo = 'acra'
owner = 'ACRA'

stats_con = Stats_db.createConnectionThreshold("#{$size_threshold.to_s}_#{Stats_db.mergeThreshold($low_threshold)}_#{Stats_db.mergeThreshold($high_threshold)}", $ONE_TO_MANY)

method_info = Stats_db.getMethodChangeInfo(stats_con, owner, repo)

date_info = Stats_db.getCommitDates(stats_con, owner, repo)
spacing_list = Hash.new
offset = 1

# Create an offset list to simplify spacing process
date_info.each do |commit_date|
    spacing_list[commit_date['commit_date'].to_s] = offset
    offset += 1
end

times_changed = 0

CO_CHANGE = :co_change
CHANGE_VERSION = :version

#progress_indicator = Progress.new("Analysis")

#$stdout.reopen("../../parse_log/analysis/ACRAacra.log", "a")

#progress_indicator.puts "Loading Methods..."
#progress_indicator.total_length = method_info.size

# TODO can we get mean distance between changes, std of ...

i = 0
#relations = RGL::DirectedAdjacencyGraph.new
#relations = Graph.new
relations = Hash.new

prev_node = nil

method_info.each_with_index do |method, index|

    #progress_indicator.percentComplete(["Number of changes the method receives #{times_changed}",
    #    "Method = #{method['method_info_id']}, #{method['signature']}"])
#puts "method date = #{method['commit_date']}"

    node = MethodNode.new(method['commit_id'], method['sha_hash'], method['method_info_id'], method['path'], method['name'], method['signature'], method['commit_date'])

    #if !relations.has_key?(node)
    #    relations.(node)
    #end

    if prev_node && node.change_version(prev_node)
        # Still the same method
        if relations[prev_node][-1].to_s != method['commit_date'].to_s
            relations[prev_node] << method['commit_date']
        end
    else
        # New method
        relations[node] = Array.new 
        relations[node] << method['commit_date']
        prev_node = node
    end    
end

#puts "relations = #{relations}"
#puts "dates = #{spacing_list}"

#puts pretty_print(relations, spacing_list)

File.open("grid_output.txt", 'w') do |f|
#    f << relations.to_dot()
    pretty_print(relations, spacing_list) do |result|
        f << result
    end
end
#{}%x(dot -Tpng test.dot -o test.png)
#relations.write_to_graphic_file('png')