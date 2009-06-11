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


module Ruote

  class ProcessStatus

    attr_reader :expressions
    attr_reader :errors

    def initialize (expressions, errors)

      @expressions = expressions
      @errors = errors
    end

    def root_expression

      @expressions.find { |e| e.fei.expid == '0' && e.fei.sub_wfid == nil }
    end

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

    def wfid

      root_expression.fei.wfid
    end

    def definition_name

      root_expression.attributes['name'] ||
      root_expression.attributes.keys.find() { |k|
        root_expression.attributes[k] == nil
      }
    end

    def definition_revision

      root_expression.attributes['revision']
    end

    def original_tree

      root_expression.original_tree
    end

    # Returns a Time instance indicating when the process instance was launched.
    #
    def launched_time

      root_expression.created_time
    end

    def to_s

      "(process_status wfid '#{wfid}', expressions #{@expressions.size})"
    end

    def current_tree

      h = Ruote.decompose_tree(original_tree)

      @expressions.sort { |e0, e1|
        e0.fei.expid <=> e1.fei.expid
      }.each { |e|
        h.merge!(Ruote.decompose_tree(e.tree, e.fei.expid))
      }

      Ruote.recompose_tree(h)
    end

    def inspect

      s = "== #{self.class} ==\n"
      s << "   expressions : #{@expressions.size}\n"
      @expressions.each do |e|
        s << "     #{e.fei.to_s} : #{e.class}\n"
      end
      s << "   errors : #{@errors.size}\n"
      @errors.each do |e|
        s << "     #{e.inspect}\n"
      end

      s
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

