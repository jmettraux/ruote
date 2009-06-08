#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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

    attr_accessor :original_tree
    attr_accessor :variables

    attr_accessor :children

    attr_accessor :on_cancel
    attr_accessor :on_error

    attr_accessor :applied_workitem

    attr_reader :in_cancel
    attr_reader :in_error


    def initialize (fei, parent_id, tree, variables, workitem)

      @fei = fei
      @parent_id = parent_id

      @original_tree = tree.dup
      @updated_tree = nil

      @in_error = false
      @in_cancel = false

      @children = []

      @variables = variables

      @applied_workitem = workitem.dup

      @on_cancel = attribute(:on_cancel, workitem)
      @on_error = attribute(:on_error, workitem)
        # not very happy with those two here...
        # merge initialize / apply ?
    end

    # Returns the parent expression of this expression instance.
    #
    def parent

      expstorage[@parent_id]
    end

    def register_child (fei, do_persist=true)

      @children << fei
      persist if do_persist
    end

    #--
    # tree
    #++

    def tree
      @updated_tree || @original_tree
    end

    def tree= (t)
      @updated_tree = t
    end

    def name
      tree[0]
    end

    def attributes
      tree[1]
    end

    def tree_children
      tree[2]
    end

    # Given something like
    #
    #   sequence do
    #     participant 'alpha'
    #   end
    #
    # in the context of the participant expression
    #
    #   attribute_text(wi)
    #
    # will yield 'alpha'.
    #
    def attribute_text (workitem)

      text = attributes.keys.find { |k| attributes[k] == nil }

      Ruote.dosub(text.to_s, self, workitem)
    end

    #--
    # apply/reply/cancel
    #++

    def do_reply (workitem)

      @children.delete(workitem.fei)
        # NOTE : check on size before/after ?

      if @in_cancel or @in_error

        if @children.size < 1
          reply_to_parent(workitem)
        else
          persist # for the updated @children
        end

      else

        reply(workitem)
      end
    end

    # The default implementation : replies to the parent expression
    #
    def reply (workitem)

      reply_to_parent(workitem)
    end

    # This default implementation cancels all the [registered] children
    # of this expression.
    #
    def cancel

      @in_cancel = true
      persist

      @children.each { |cfei| pool.cancel_expression(cfei) }
    end

    # Forces error handling by this expression.
    #
    def fail

      @in_error = true
      persist

      @children.each { |cfei| pool.cancel_expression(cfei) }
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

      args.each { |a| a = a.to_s; return a if attributes[a] != nil }

      nil
    end

    def attribute (n, workitem, options={})

      n = n.to_s

      default = options[:default]
      escape = options[:escape]
      string = options[:to_s] || options[:string]

      v = attributes[n]

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
    # on_cancel / on_error
    #++

    def lookup_on (type)

      if self.send("on_#{type}")
        self
      elsif @parent_id
        parent.lookup_on(type)
      else
        nil
      end
    end

    #--
    # variables
    #++

    # Looks up the value of a variable in expression tree
    # (seen from a leave, it looks more like a stack than a tree)
    #
    def lookup_variable (var, prefix=nil)

      #p [ :lv, var, prefix, @variables ]

      var, prefix = split_prefix(var, prefix)

      return parent.lookup_variable(var, prefix) \
        if @parent_id && prefix.length > 0

      if @variables

        val = @variables[var]
        return val if val != nil

      elsif @parent_id

        return parent.lookup_variable(var, prefix)

      #else # engine level
      end

      nil
    end

    # Sets a variable to a given value.
    # (will set at the appropriate level).
    #
    def set_variable (var, val, prefix=nil)

      var, prefix = split_prefix(var, prefix)

      return parent.set_variable(var, val, prefix) \
        if @parent_id && prefix.length > 0

      if @variables

        @variables[var] = val

        persist
          # very important, persisting...

      elsif @parent_id

        parent.set_variable(var, val, prefix)

      #else # should not happen
      end
    end

    #--
    # serialization
    #
    # making sure '@context' is not serialized
    #++

    def marshal_dump #:nodoc#

      iv = instance_variables
      iv.delete(:@context)
      iv.delete('@context')
      iv.inject({}) { |h, vn| h[vn] = instance_variable_get(vn); h }
    end

    def marshal_load (s) #:nodoc#

      s.each { |k, v| instance_variable_set(k, v) }
    end

    def to_yaml_properties #:nodoc#

      l = super
      l.delete(:@context)
      l.delete('@context')
      l
    end

    protected

    VAR_PREFIX_REGEX = /^(\/*)/

    # Used by lookup_variable and set_variable to extract the
    # prefix in a variable name
    #
    def split_prefix (var, prefix)

      if (not prefix)
        m = VAR_PREFIX_REGEX.match(var)
        prefix = m ? m[1][0, 2] : ''
        var = var[prefix.length..-1]
      end

      [ var, prefix ]
    end

    def apply_child (child_index, workitem)

      pool.apply_child(self, child_index, workitem)
    end

    # Asks expstorage[s] to store/update persisted version of self.
    #
    def persist

      wqueue.emit(:expressions, :update, :expression => self)
    end

    # Asks expstorage[s] to unstore persisted version of self.
    #
    def unpersist

      wqueue.emit(:expressions, :delete, :fei => @fei)
    end

    def reply_to_parent (workitem)

      if @in_error
        trigger_on_error(workitem)
      elsif @in_cancel and @on_cancel
        trigger_on_cancel(workitem)
      else
        pool.reply_to_parent(self, workitem)
      end
    end

    # if any on_cancel handler is present, will trigger it.
    #
    def trigger_on_cancel (workitem)

      pool.send(:apply,
        :tree => [ @on_cancel, {}, [] ],
        :fei => fei,
        :parent_id => @parent_id,
        :workitem => @applied_workitem,
        :variables => @variables)
    end

    def trigger_on_error (workitem)

      handler = @on_error.to_s

      if handler == 'undo' # which got just done (cancel)

        pool.reply_to_parent(self, workitem)

      else # handle

        pool.send(:apply,
          :tree => handler == 'redo' ? tree : [ handler, {}, [] ],
          :fei => @fei,
          :parent_id => @parent_id,
          :workitem => @applied_workitem,
          :variables => @variables)
      end
    end
  end
end

