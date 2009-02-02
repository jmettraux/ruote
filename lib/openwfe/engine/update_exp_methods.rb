#
#--
# Copyright (c) 2007-2009, John Mettraux, OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

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

