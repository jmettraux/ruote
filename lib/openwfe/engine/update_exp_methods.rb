#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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
  # The methods of the engine for updating live expressions
  # (in flight modifications of process instances)
  #
  module UpdateExpMethods

    #
    # Use only when doing "process gardening".
    #
    # This method updates an expression, the 'data' parameter is expected
    # to be a hash. If the expression is an Environment, the variables
    # will be merged with the ones found in the data param.
    # If the expression is not an Environment, the data will be merged
    # into the 'applied_workitem' if any.
    #
    # If the merge is not possible, an exception will be raised.
    #
    def update_expression_data (fei, data)

      fexp = fetch_exp fei

      original = if fexp.is_a?(Environment)

        fexp.variables
      else

        fexp.applied_workitem.attributes
      end

      original.merge! data

      get_expression_pool.update fexp
    end

    #
    # A variant of update_expression() that directly replaces
    # the raw representation stored within an expression
    #
    # Useful for modifying [not yet reached] segments of processes.
    #
    # If the index argument is set, only the raw child pointed by the index
    # will get updated.
    #
    def update_expression_tree (fei, representation, index=nil)

      fexp = fetch_exp(fei)

      #raise "cannot update already applied expression" \
      #  unless fexp.is_a?(RawExpression)

      if index
        #
        # update just one child
        #

        fexp.raw_representation = fexp.raw_representation.dup
        fexp.raw_representation[2] = fexp.raw_representation[2].dup
          # those dups are for the InMemory case ...

        fexp.raw_representation[2][index] = representation
      else
        #
        # update whole tree
        #
        fexp.raw_representation = representation
      end

      fexp.raw_rep_updated = true

      get_expression_pool.update(fexp)
    end

    alias :update_raw_expression :update_expression_tree

    #
    # Replaces an expression in the pool with a newer version of it.
    #
    # (useful when fixing processes on the fly)
    #
    def update_expression (fexp)

      fexp.application_context = application_context

      fexp.raw_rep_updated = true

      get_expression_pool.update(fexp)
    end

  end

end

