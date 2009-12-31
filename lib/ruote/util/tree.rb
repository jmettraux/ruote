#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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

  # Turning a tree into a numbered string view
  #
  #   require 'ruote/util/tree'
  #   require 'ruote/parser/ruby_dsl'
  #
  #   pdef = Ruote.process_definition :name => 'def0' do
  #     sequence do
  #       alpha
  #       bravo
  #     end
  #   end
  #
  #   p pdef
  #     # => ["define", {"name"=>"def0"}, [["sequence", {}, [["alpha", {}, []], ["bravo", {}, []]]]]]
  #
  #   puts Ruote.tree_to_s(pdef)
  #     # =>
  #     #    0  define {"name"=>"def0"}
  #     #      0_0  sequence {}
  #     #        0_0_0  alpha {}
  #     #        0_0_1  bravo {}
  #
  def Ruote.tree_to_s (tree, expid='0')

    d = expid.split('_').size - 1
    s = "#{' ' * d * 2}#{expid}  #{tree[0]} #{tree[1].inspect}\n"
    tree[2].each_with_index { |t, i| s << tree_to_s(t, "#{expid}_#{i}") }
    s
  end
end

