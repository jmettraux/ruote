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
module Exp
  # just introducing the namespace
end
end

require 'ruote/exp/flow_expression'


exppath = File.join(File.dirname(__FILE__), '..', 'exp')

Dir.new(exppath).entries.sort.each do |pa|
  require(File.join('ruote', 'exp', pa)) if pa.match(/^fe_.*\.rb$/)
end


module Ruote

  #
  # Mapping from expression names (sequence, concurrence, ...) to expression
  # classes (Ruote::SequenceExpression, Ruote::ConcurrenceExpression, ...)
  #
  # Requiring this ruote/svc/expression_map.rb file will automatically load
  # all the expressions in ruote/exp/fe_*.rb.
  #
  # When the ExpressionMap is
  # instantiated by the engine, it will look at the Ruote::Exp namespace
  # and register as expression any constant in there whose name ends with
  # "Expression", like "SequenceExpression" or "ParticipantExpression".
  #
  # So adding expressions to ruote should be as simple as making sure the
  # engine sees your classes under Ruote::Exp before it instantiates this
  # expression map (so that the expression map will automatically register
  # your expressions).
  #
  class ExpressionMap

    # Will load any expression in the Ruote::Exp:: namespace and map
    # its names to its class.
    #
    def initialize(worker)

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
    def expression_class(exp_name)

      @map[exp_name]
    end

    protected

    def add(exp_class)

      exp_class.expression_names.each { |n| @map[n] = exp_class }
    end
  end
end

