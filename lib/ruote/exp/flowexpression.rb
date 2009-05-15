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

require 'ruote/util/ometa'
require 'ruote/engine/context'


module Ruote

  class FlowExpression < ObjectWithMeta

    include EngineContext

    attr_accessor :fei
    attr_accessor :parent_id

    attr_accessor :tree
    attr_accessor :children

    def initialize (fei, parent_id, tree)

      @fei = fei
      @parent_id = parent_id

      @tree = tree.dup
      @children = []
    end

    def name
      @tree[0]
    end

    def attributes
      @tree[1]
    end

    def raw_children
      @tree[2]
    end

    # The default implementation : replies to the parent expression
    #
    def reply (workitem)

      reply_to_parent(workitem)
    end

    def cancel

      @children.each { |cfei| pool.cancel(cfei) }
    end

    #def on_error
    #  if oe = attributes['on_error']
    #    p oe
    #    true
    #  else
    #    false
    #  end
    #end
    #def on_cancel
    #  if oc = attributes['on_cancel']
    #    p oc
    #    true
    #  else
    #    false
    #  end
    #end

    # Keeping track of names and aliases for the expression
    #
    def self.names (*exp_names)

      exp_names = exp_names.collect { |n| n.to_s }
      meta_def(:expression_names) { exp_names }
    end

    # Returns true if this expression is a a definition
    # (define, process_definition, set, ...)
    #
    def self.is_definition?

      false
    end

    # This method makes sure the calling class responds "true" to is_definition?
    # calls.
    #
    def self.is_definition

      meta_def(:is_definition) { true }
    end

    protected

    def apply_child (child_index, workitem)

      pool.apply_child(self, child_index, workitem)
    end

    def store_self

      wqueue.emit(:expressions, :update, :expression => self)
    end

    def reply_to_parent (workitem)

      pool.reply_to_parent(self, workitem)
    end
  end
end

