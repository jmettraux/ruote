#
#--
# Copyright (c) 2008, John Mettraux, OpenWFE.org
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
    def representation

      update_rep(find_root_expression)
    end

    #
    # 'tree' is probably a better name than representation
    #
    alias :tree :representation

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
      def update_rep (flow_expression)

        rep = flow_expression.raw_representation.dup
        children = flow_expression.children

        index = -1

        rep[2] = rep.last.inject([]) { |r, c|

          index += 1

          r << if c.is_a?(Array)

            child_fei = flow_expression.children[index]
            child_exp = find_expression child_fei

            if child_exp
              update_rep(child_exp)
            else
              #c[1]['__gone__'] = true
                #
                # not a good idea
                # have to differentiate between 'replied'
                # expressions and removed expressions
              c
            end
          else

            c
          end

        } if children and children.size > 0

        rep
      end
  end
end
