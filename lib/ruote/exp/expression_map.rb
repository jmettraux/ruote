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
module Exp
  # just introducing the namespace
end
end

require 'ruote/exp/flowexpression'


exppath = File.dirname(__FILE__)

Dir.new(exppath).entries.select { |p|
  p.match(/^fe_.*\.rb$/)
}.each { |p|
  require exppath + '/' + p
}


module Ruote

  #
  # Mapping from expression names (sequence, concurrence, ...) to expression
  # classes (Ruote::SequenceExpression, Ruote::ConcurrenceExpression, ...)
  #
  class ExpressionMap

    # Will load any expression in the Ruote::Exp:: namespace and map
    # its names to its class.
    #
    def initialize (worker)

      @map = {}

      Ruote::Exp.constants.each do |con|

        con = con.to_s
        next unless con.match(/Expression$/)

        cla = Ruote::Exp.const_get(con)
        next unless cla.respond_to?(:expression_names)

        add(cla)
      end
    end

    # Returns the expression class for the given expression name
    #
    def expression_class (exp_name)

      @map[exp_name]
    end

    protected

    def add (exp_class)

      exp_class.expression_names.each { |n| @map[n] = exp_class }
    end
  end
end

