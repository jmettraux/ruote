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
require 'ruote/util/dollar'
require 'ruote/engine/context'


module Ruote

  class FlowExpression < ObjectWithMeta

    include EngineContext

    attr_accessor :fei
    attr_accessor :parent_id

    attr_accessor :tree
    attr_accessor :children

    attr_accessor :variables


    def initialize (fei, parent_id, tree, variables)

      @fei = fei
      @parent_id = parent_id

      @tree = tree.dup
      @children = []

      @variables = variables
    end

    def parent
      expstorage[@parent_id]
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

    def attribute_text (workitem)

      text = @tree[1].keys.find { |k| @tree[1][k] == nil }

      Ruote.dosub(text.to_s, self, workitem)
    end

    # The default implementation : replies to the parent expression
    #
    def reply (workitem)

      reply_to_parent(workitem)
    end

    def cancel

      @children.each { |cfei| pool.cancel(cfei) }
    end

    #--
    # meta stuff
    #++

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

      meta_def(:is_definition?) { true }
    end

    #--
    # attributes
    #++

    def has_attribute (*args)

      args.each { |a| a = a.to_s; return a if @tree[1][a] != nil }

      nil
    end

    def attribute (n, workitem, options={})

      n = n.to_s

      default = options[:default]
      escape = options[:escape]
      string = options[:to_s] || options[:string]

      v = @tree[1][n]

      v = if v == nil
        default
      elsif escape
        v
      else
        Ruote.dosub(v, self, workitem)
      end

      v = v.to_s if v and string

      v
    end

    #--
    # variables
    #++

    #ENGINE_LEVEL_VAR = /^\/\/[^\/ ]+/
    PROCESS_LEVEL_VAR = /^\/([^\/ ]+)/

    def lookup_variable (var)

      if m = PROCESS_LEVEL_VAR.match(var)

        return expstorage.root_expression(wfid).lookup_variable(m[1])
      end

      if @variables

        val = @variables[var]
        return val if val != nil

      elsif @parent_id

        return parent.lookup_variable(var)

      #else # engine level
      end

      nil
    end

    def set_variable (var, val)

      if m = PROCESS_LEVEL_VAR.match(var)

        expstorage.root_expression(wfid).set_variable(m[1], var)
        return
      end

      if @variables

        @variables[var] = val

        persist
          # very important, persisting...

      elsif @parent_id

        parent.set_variable(var, val)

      #else # should not happen
      end
    end

    protected

    def apply_child (child_index, workitem)

      pool.apply_child(self, child_index, workitem)
    end

    def persist

      wqueue.emit(:expressions, :update, :expression => self)
    end

    def reply_to_parent (workitem)

      pool.reply_to_parent(self, workitem)
    end
  end
end

