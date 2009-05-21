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


require 'ruote/exp/flowexpression'


module Ruote

  class DefineExpression < FlowExpression

    is_definition

    names :define, :process_definition, :workflow_definition

    def apply (workitem)

      self.tree = self.class.reorganize(expmap, tree)

      name = attribute(:name, workitem) || attribute_text(workitem)

      # TODO : what if no name ??

      set_variable(name, tree)

      reply_to_parent(workitem)
    end

    # Used by instances of this class and also the expression pool,
    # when launching a new process instance.
    #
    def self.reorganize (expmap, tree)

      definitions, bodies = tree[2].partition { |b| expmap.is_definition?(b) }

      [ 'sequence', tree[1], definitions + bodies ]
    end
  end
end

