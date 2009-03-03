#--
# Copyright (c) 2008-2009, John Mettraux, jmettraux@gmail.com
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


module OpenWFE

  #
  # This module gets included into the result of the expression pool (and
  # engine) process_stack method (if the optional parameter 'unapplied' is
  # set to true).
  #
  # It adds a representation() method that returns an up-to-date
  # representation of the executing process instance.
  # This representation is suitable for 'fluo' rendering.
  #
  module RepresentationMixin

    #
    # Computes and returns the up-to-date representation of
    # the process definition (on the fly changes included)
    #
    # A 'representation' is an array
    # [ expression_name, attributes, children_expression ] where
    # expression_name is a String, attributes a Hash and children_expression
    # an Array of representations.
    #
    def tree

      get_updated_rep(find_root_expression)
    end

    #
    # Returns the tree as it was when the process instance was launched.
    #
    # (Where as tree() includes 'in-flight' manipulations)
    #
    def initial_tree

      find_root_expression.raw_representation
    end

    #
    # Returns the root expression (the one with no parent expression)
    # among the expressions in self (Array of FlowExpression instances).
    #
    def find_root_expression

      self.find do |fexp|
        fexp.fei.expid == '0' &&
        ( ! fexp.is_a?(OpenWFE::Environment)) &&
        fexp.fei.is_in_parent_process?
      end
    end

    #
    # Returns an expression given its FlowExpressionId.
    #
    def find_expression (fei)

      self.find { |fexp| fexp.fei == fei }
    end

    protected

      #
      # If a child expression is present (in the process stack)
      # makes sure to take its current representation and include
      # it in the parent representation.
      #
      def get_updated_rep (flow_expression)

        rep = flow_expression.raw_representation.dup
        rep[2] = rep[2].dup

        (flow_expression.children || []).each do |fei|
          fexp = find_expression(fei)
          next unless fexp
          rep[2][fei.child_id.to_i] = get_updated_rep(fexp)
        end

        rep
      end
  end
end
