#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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


require 'ruote/exp/fe_sequence'


module Ruote

  class DefineExpression < SequenceExpression

    is_definition

    names :define, :process_definition, :workflow_definition

    attr_accessor :original_children

    def apply (workitem)

      @original_children = @tree[2]

      definitions, bodies = @tree[2].partition { |b| expmap.is_definition?(b) }

      @tree[2] = bodies

      definitions.each do |d|

        if name = d[1]['name']

          name = Ruote.dosub(name, self, workitem)
          set_variable(name, d)
        end
      end

      if (@variables && @variables.size > 0) || @tree[2] != @original_children
        persist
      end

      #
      # start execution

      reply(workitem)
    end
  end
end

