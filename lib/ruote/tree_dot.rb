#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


module Ruote

  # Turns a process definition tree to a graphviz dot representation.
  #
  # http://www.graphviz.org
  #
  def self.tree_to_dot(tree, name='ruote process definition')

    s = "digraph \"#{name}\" {\n"
    s << branch_to_dot('0', tree).join("\n")
    s << "\n}\n"
  end

  protected

  def self.branch_to_dot(expid, exp)

    [
      "  \"#{expid}\" "+
      "[ label = \"#{exp[0]} #{exp[1].inspect.gsub("\"", "'")}\" ];"
    ] +
    children_to_dot(expid, exp)
  end

  def self.children_to_dot(expid, exp)

    exp_name = exp[0]
    child_count = exp[2].size

    i = -1

    a = exp[2].collect do |child|
      i += 1
      branch_to_dot("#{expid}_#{i}", child)
    end

    if child_count > 0 # there are children

      if %w[ concurrence if ].include?(exp_name)

        (0..child_count - 1).each do |i|
          a << "  \"#{expid}\" -> \"#{expid}_#{i}\";"
          a << "  \"#{expid}_#{i}\" -> \"#{expid}\";"
        end

      else

        a << "  \"#{expid}\" -> \"#{expid}_0\";"
        a << "  \"#{expid}_#{child_count -1}\" -> \"#{expid}\";"

        (0..child_count - 2).each do |i|
          a << "  \"#{expid}_#{i}\" -> \"#{expid}_#{i + 1}\";"
        end
      end
    end

    a
  end
end

