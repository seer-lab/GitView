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

    attr_accessor :commit_id, :sha, :method_id, :path, :name,
        :signature, :commit_date, :prev_name, :change_type, :next_method_id

    def initialize(commit_id, sha, method_id, path, name, signature, commit_date, change_type, prev_name, next_method_id=nil)
        @commit_id = commit_id
        @sha = sha
        @method_id = method_id
        @path = path
        @name = name
        @signature = signature
        @commit_date = commit_date.to_s
        @change_type = change_type
        @prev_name = Array.new
        if prev_name
            @prev_name << prev_name
        end
        @next_method_id = next_method_id
    end

    def identifier
        return method_id
    end

    #def ==(other)
    #    return class_check(other) && @commit_id == other.commit_id && @method_id == other.method_id
    #end

    def change_version(other)
        return class_check(other) && self != other && @path == other.path && @name == other.name && @signature == other.signature
    end

    def same?(other)
        return change_version(other) && @commit_id == other.commit_id && @method_id == other.method_id
    end

    def has_prev_name?
        return @prev_name && !@prev_name.empty?
    end

    def prev_name?(other)
        if other == nil || self == other || !other.has_prev_name?
            return false
        end

        if signature == other.signature

        end

        #a = gets
  
        @prev_name.each do |prev_name|
            if other.prev_name.first == prev_name 
                return true
            end
        end

        if "#{@path}#{@name}" == other.prev_name.first 
            return true
        end

        return false
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

    def >(other)
        return !@prev_name.empty? && !other.prev_name.empty? && @prev_name.first >= other.prev_name.first && @signature >= other.signature && @commit_date > other.commit_date
    end

    def <(other)
        return !@prev_name.empty? && !other.prev_name.empty? && @prev_name.first <= other.prev_name.first && @signature <= other.signature && @commit_date < other.commit_date
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

    node_string = "          commits\n"
    node_string += "methods\n"
    yield node_string
    node_string = ""
    prev_node = nil

    graph.each do |node, edges|

        if prev_node && node.change_version(prev_node)
            # Do nothing
        else
            if node.method_id.to_s.length > 10
                node_string += node.method_id.to_s[0..10]
            else
                node_string += node.method_id.to_s
                node_string += " " * (10 - node.method_id.to_s.size)
            end
            node_string += "|"

            #puts "Node:"

            prev_offset = 0
            cur_offset = 0
            deleted = false
            filler = " "
            row = ""
            #puts "edge = #{edges}"
            #if !edges['prev'].empty?
            #    puts "edge children = #{edges['prev']}"
            #    a = gets
            #end
            edges['dates'].each_with_index do |edge, i|
                # Since the dates are ordered we just have to go through and use the offset - prev_offset
                offset = spacing_list[edge.commit_date]
                cur_offset = offset - prev_offset - 1
                if row.size > spacing_list.size
                    puts "#{edge}"
                    #yield "edge.commit_date = #{edge.commit_date.to_s}, offset #{offset}, prev_offset #{prev_offset}, cur_offset #{cur_offset}, rowsize = #{row.size} "
                    #yield edges.to_s
                end

                #if edge.has_prev_name?
                #    puts "\tnode #{edge.to_s}, date = #{edge.commit_date}, change = #{edge.change_type}, prev_name = #{edge.prev_name}"
                #    a = gets
                #end

                cur_offset.times do |x|
                    row += add_element(filler)
                end

                if edge.change_type.to_i != 0
                    row += add_element("*")
                else
                    row += add_element("+")
                end
                    
                

                prev_offset = offset

                if edge.change_type.to_i == 2
                    deleted = true
                end
                filler = nil
            end

            if !deleted            
                if spacing_list.size > row.size
                    row += "-" * (spacing_list.to_a[-1][-1] - row.size)
                end
            end
            node_string += "#{row}\n"
            yield node_string
            node_string = ""
        end
    end
    #return node_string
end

def sort_output(offset, type)
    sorted = File.open("grid_output_#{type.to_s}_sorted.txt", 'w')

    lines = Array.new
    i = 0
    File.open("grid_output_#{type.to_s}.txt", 'r') do |f|
        f.each_line do |line|
            if i > 1
                lines << line
            end
            i += 1
        end
    end

    # Sort by the range that states the commit (rather than the method identifier) and then reverse it so that we are looking at oldest to newest commit.
    result = lines.sort_by {|line| line[offset..-1]}.reverse

    result.each do |line|

        sorted << line
    end

    sorted.close
end

def clean_change_type(change_type, type)
    if type != :commit
        return change_type.split(/,/)[-1]        
    end
    return change_type
end

def find_node(node_hash, method_id)
    node_hash.keys.each_with_index do |element, index|
        puts "ele = #{element.method_id}, meth #{method_id}"
        if element.method_id == method_id
            puts "found"
            return index
        end
    end
    return nil
end

def check_next(node, node_hash)

    index = find_node(node_hash, node.next_method_id)
    if index
        
        node_hash[node]['next_node'] << node_hash.keys[index]

        node_hash = check_next(node_hash.keys[index], node_hash)

        # Add the children from the next node.
        if !node_hash[node_hash.keys[index]]['next_node'].empty?
            node_hash[node]['next_node'] += node_hash[node_hash.keys[index]]['next_node']
        end

        # Delete the next node since it is not needed any more
        node_hash.delete(node_hash.keys[index])
    end

    # No next node return the node_hash unchanged
    return node_hash
end

#b = MethodNode.new(1323, 'dfasdf24fvaefama', 42, 'CrashReport/sample/org/acra/sampleapp/', 'CrashTest.java', '@Override public String getFormId() {')

$high_threshold = 0.5
$ONE_TO_MANY = true
$low_threshold, $size_threshold = 0.8, 20

repo = 'acra'
owner = 'ACRA'
type = :commit

stats_con = Stats_db.createConnectionThreshold("#{$size_threshold.to_s}_#{Stats_db.mergeThreshold($low_threshold)}_#{Stats_db.mergeThreshold($high_threshold)}", $ONE_TO_MANY)

method_info = nil
date_info = nil
prev_method_info = nil

if type == :commit
    method_info = Stats_db.getMethodChangeInfo(stats_con, owner, repo)
    date_info = Stats_db.getCommitDates(stats_con, owner, repo)
    prev_method_info = Stats_db.getMethodChangeInfoRename(stats_con, owner, repo)
else
    method_info = Stats_db.getMethodRangeInfo(stats_con, owner, repo, type)
    date_info = Stats_db.getCommitDatesRange(stats_con, owner, repo, type)
end


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

prev_index = 0

rename_node = Array.new
rename_node_list = Hash.new

prev_method_info.each do |prev_method|
    rename_node << MethodNode.new(prev_method['commit_id'], prev_method['sha_hash'],
        prev_method['method_info_id'], prev_method['path'], prev_method['name'],
        prev_method['signature'], prev_method['commit_date'].to_s,
        clean_change_type(prev_method['change_type'], type), prev_method['previous_name'],
        prev_method['next_method_info_id'])
    rename_node_list[rename_node[-1]] = Hash.new
    rename_node_list[rename_node[-1]]['next_node'] = Array.new
    rename_node_list[rename_node[-1]]['parent'] = nil
    rename_node_list[rename_node[-1]]['index'] = prev_index
    prev_index+=1
end

# Handle double or more renaming
rename_node_list.keys.each_with_index do |re_node, index|

    rename_node_list = check_next(re_node, rename_node_list)
    #a = gets
end

rename_node_list.keys.each_with_index do |re_node, index|
    puts "rename_nodes[#{index}] = #{rename_node_list[re_node]}"
end

a = gets

prev_index = 0
parent_link = false
dump = false
debug = false

rename_connections = Array.new

method_info.each_with_index do |method, index|

    #progress_indicator.percentComplete(["Number of changes the method receives #{times_changed}",
    #    "Method = #{method['method_info_id']}, #{method['signature']}"])
#puts "method date = #{method['commit_date']}"
    
    change_type = clean_change_type(method['change_type'], type)

    node = MethodNode.new(method['commit_id'], method['sha_hash'], method['method_info_id'],
        method['path'], method['name'], method['signature'], method['commit_date'].to_s,
        change_type, method['previous_name'])

    #if !relations.has_key?(node)
    #    relations.(node)
    #end

    #if prev_node
    #    puts "other.name = #{prev_node.prev_name}, path = #{prev_node.path}, other_name = #{prev_node.name}"
    #else
    #    puts "other = nil"
    #end
    #puts "cur_prev_name = #{node.prev_name}, path = #{node.path}, cur_name = #{node.name}"

    #a = gets

    #puts node.path
    #puts node.signature

    if prev_node && node.change_version(prev_node)

        if node.commit_id != relations[prev_node]['dates'][-1].commit_id       
            # Still the same method
            if relations[prev_node]['dates'][-1] != node
                relations[prev_node]['dates'] << node
            end
        else
            # Node or prev node is/are anon method within the class and cannot properly be tracked dump this one
            dump = true
        end
    else
        # New method
        relations[node] = Hash.new
        relations[node]['dates'] = Array.new
        relations[node]['next'] = Array.new
        relations[node]['dates'] << node
        prev_node = node
    end
    

    if !dump
        # Link original parent to the final renamed node
        rename_connections.each_with_index do |connection, index|

            # Not all of these connections are found (since some will contain no commits)

            if connection['next_method_id'] == node.method_id
                #a = gets
                relations[connection['parent']]['next'] << node
                rename_connections.delete_at(index)
                parent_link = true
                break
            end
        end

        if !parent_link
            # Link parent to children that have been renamed
            if prev_index < rename_node_list.keys.size
                #puts "prev = #{rename_node_list.keys[prev_index]}"
                #puts "node = #{node}"        
               
                if node.same?(rename_node_list.keys[prev_index])

                    #puts "equal"
                    #puts "rename_node[#{rename_node_list.keys[prev_index]}] = #{rename_node_list[rename_node_list.keys[prev_index]]}"
                    

                    # Merge the list of next_nodes
                    if !rename_node_list[rename_node_list.keys[prev_index]]['next_node'].empty?
                        puts "Merging nodes"
                        # TODO fix this, currently the list requires that the nodes are in the list are ordered by date.
                        relations[prev_node]['next'] += rename_node_list[rename_node_list.keys[prev_index]]['next_node']
                        rename_connections << {'parent' => prev_node, 'next_method_id' => relations[prev_node]['next'][-1].next_method_id}
                        #relations[prev_node]['next_method_id'] = relations[prev_node]['next'][-1].next_method_id
                    else
                        #relations[prev_node]['next_method_id'] = rename_node_list.keys[prev_index].next_method_id
                        rename_connections << {'parent' => prev_node, 'next_method_id' => rename_node_list.keys[prev_index].next_method_id}
                    end

                    prev_index += 1            
                end
            end
        else
            puts "Parent Link found"
            parent_link = false
        end
    else
        dump = false
    end
end

puts "rename_size = #{rename_connections.size}"

method_info.each_with_index do |method, index|

    #progress_indicator.percentComplete(["Number of changes the method receives #{times_changed}",
    #    "Method = #{method['method_info_id']}, #{method['signature']}"])
#puts "method date = #{method['commit_date']}"
    
    change_type = clean_change_type(method['change_type'], type)

    node = MethodNode.new(method['commit_id'], method['sha_hash'], method['method_info_id'],
        method['path'], method['name'], method['signature'], method['commit_date'].to_s,
        change_type, method['previous_name'])

    rename_connections.each_with_index do |connection, index|

        # Not all of these connections are found (since some will contain no commits)
        #puts "connections[#{index}]['parent']  = #{connection['parent']}"
        #puts "connections[#{index}]['next_method_id']  = #{connection['next_method_id']}, node.method_id = #{node.method_id}"
        #a = gets

        if connection['next_method_id'] == node.method_id
            #a = gets
            relations[connection['parent']]['next'] << node
            rename_connections.delete_at(index)
            parent_link = true
            break
        end
    end
end


puts "rename_size = #{rename_connections.size}"
#=end


rename_nodes = Array.new
rename_nodes << Hash.new

#MethodNode.new(
#rename_nodes[0]['method_info_id']

=begin
def merge_sort(m)
  return m if m.length <= 1
 
  middle = m.length / 2
  left = merge_sort(m[0...middle])
  right = merge_sort(m[middle..-1])
  merge(left, right)
end
 
def merge(left, right)
  result = []
  until left.empty? || right.empty?
    result << (left.first<right.first ? left.shift : right.shift)
  end
  result + left + right
end

sorted_list = relations.keys
sorted = merge_sort(sorted_list)

prev_node = nil
sorted.each do |node|

    if prev_node
        if node.prev_name?(prev_node)
            relations[prev_node] << node.commit_date
            prev_node.prev_name << "#{node.path}#{node.name}"
        end
    end
    prev_node = node

end
=end

#puts "relations = #{relations}"
#puts "dates = #{spacing_list}"

#puts pretty_print(relations, spacing_list)

# TODO fix the issue with merged commits showing up incorrectly.
File.open("grid_output_#{type.to_s}.txt", 'w') do |f|
#    f << relations.to_dot()
    pretty_print(relations, spacing_list) do |result|
        f << result
    end
end

sort_output(11, type)

#{}%x(dot -Tpng test.dot -o test.png)
#relations.write_to_graphic_file('png')

=begin
if key.has_prev_name?
     # Previous name is avaialble
     relations.keys do |inKey|
         if key != inKey && !key.change_version(inKey)
             # Not the same
             if key.prev_name?(inKey)
                 
             end
         end
     end
end    
=end