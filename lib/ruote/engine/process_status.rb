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

require 'ruote/engine/process_error'


module Ruote

  #
  # A 'view' on the status of a process instance.
  #
  # Returned by the #process and the #processes methods of the Engine.
  #
  class ProcessStatus

    # The expressions that compose the process instance.
    #
    attr_reader :expressions

    # An array of errors currently plaguing the process instance. Hopefully,
    # this array is empty.
    #
    attr_reader :errors

    def initialize (context, expressions, errors)

      @expressions = expressions.collect { |e|
        Ruote::Exp::FlowExpression.from_h(context, e) }

      @errors = errors.collect { |e|
        ProcessError.new(e) }
    end

    # Returns the expression at the root of the process instance.
    #
    def root_expression

      @expressions.find { |e| e.fei.expid == '0' && e.fei.sub_wfid == nil }
    end

    # Returns the process variables set for this process instance.
    #
    def variables

      root_expression.variables
    end

    # Returns a hash fei => variable_hash containing all the variable bindings
    # (expression by expression) of the process instance.
    #
    def all_variables

      @expressions.inject({}) do |h, exp|
        h[exp.fei] = exp.variables if exp.variables
        h
      end
    end

    # Returns a hash tagname => fei of tags set at the root of the process
    # instance.
    #
    def tags

      variables.select { |k, v| v.is_a?(FlowExpressionId) }
    end

    # Returns a hash tagname => array of feis of all the tags set in the process
    # instance.
    #
    def all_tags

      all_variables.inject({}) do |h, (fei, vars)|
        vars.each { |k, v| (h[k] ||= []) << v if v.is_a?(FlowExpressionId) }
        h
      end
    end

    # Returns the unique identifier for this process instance.
    #
    def wfid

      root_expression.fei.wfid
    end

    def definition_name

      root_expression.attribute('name') || root_expression.attribute_text
    end

    def definition_revision

      root_expression.attribute('revision')
    end

    # Returns the process definition tree as it was when this process instance
    # was launched.
    #
    def original_tree

      root_expression.original_tree
    end

    # Returns a Time instance indicating when the process instance was launched.
    #
    def launched_time

      root_expression.created_time
    end

    def to_s

      "(process_status wfid '#{wfid}', " +
      "expressions #{@expressions.size}, " +
      "errors #{@errors.size})"
    end

    def inspect

      s = "== #{self.class} ==\n"
      s << "   expressions : #{@expressions.size}\n"
      @expressions.each do |e|
        s << "     #{e.fei.to_storage_id} : #{e}\n"
      end
      s << "   errors : #{@errors.size}\n"
      @errors.each do |e|
        s << "     #{e.inspect}\n"
      end

      s
    end

    def to_h

      h = {}

      %w[
        wfid
        definition_name definition_revision
        original_tree current_tree
        variables tags
      ].each { |m| h[m] = self.send(m) }

      h['launched_time'] = launched_time.to_s

      # all_variables and all_tags ?

      h['root_expression'] = nil
      h['expressions'] = @expressions.collect { |e| e.fei.to_h }
      h['errors'] = @errors.collect { |e| e.to_h(true) }

      h
    end

    # Returns the current version of the process definition tree. If no
    # manipulation (gardening) was performed on the tree, this method yields
    # the same result as the #original_tree method.
    #
    def current_tree

      h = Ruote.decompose_tree(original_tree)

      @expressions.sort { |e0, e1|
        e0.fei.expid <=> e1.fei.expid
      }.each { |e|
        tree = if v = e.tree[1]['_triggered']
          t = original_tree_from_parent(e).dup
          t[1]['_triggered'] = v
          t
        else
          e.tree
        end
        h.merge!(Ruote.decompose_tree(tree, e.fei.expid))
      }

      Ruote.recompose_tree(h)
    end

    protected

    def original_tree_from_parent (e)

      parent = @expressions.find { |exp| exp.fei == e.parent_id }

      parent ? parent.tree[2][e.fei.child_id] : e.tree
    end
  end

  def self.decompose_tree (t, pos='0', h={})

    h[pos] = t[0, 2]
    t[2].each_with_index { |c, i| decompose_tree(c, "#{pos}_#{i}", h) }
    h
  end

  def self.recompose_tree (h, pos='0')

    t = h[pos]

    return nil unless t

    t << []

    i = 0

    loop do
      tt = recompose_tree(h, "#{pos}_#{i}")
      break unless tt
      t.last << tt
      i = i + 1
    end

    t
  end
end

