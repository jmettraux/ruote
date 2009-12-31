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


module Ruote::Exp

  #
  # Here are examples of the 'if' expression in use :
  #
  #   _if do
  #     equals :field_value => 'customer', :other_value => 'British Petroleum'
  #     participant :ref => 'Allister'
  #   end
  #
  # and :
  #
  #   _if :test => '${f:customer} == British Petroleum' do
  #     participant :ref => 'Allister'
  #   end
  #
  # An else clause is accepted :
  #
  #   _if do
  #     equals :field_value => 'customer', :other_value => 'British Petroleum'
  #     participant :ref => 'Allister'
  #     participant :ref => 'Bernardo'
  #   end
  #
  # or :
  #
  #   _if :test => '${f:customer} == British Petroleum' do
  #     participant :ref => 'Allister'
  #     participant :ref => 'Bernardo'
  #   end
  #
  # Note that any expression accepts an :if attribute :
  #
  #   participant :ref => 'Al', :if => '${f:customer} == British Petroleum'
  #
  #
  # == shorter
  #
  # It's ok to shortcircuit the _if expression like this :
  #
  #   _if '${f:customer.name} == Fred' do
  #     subprocess 'premium_course'
  #     subprocess 'regular_course'
  #   end
  #
  class IfExpression < FlowExpression

    names :if

    def apply

      reply(h.applied_workitem)
    end

    # called by 'else', 'then' or perhaps 'equals'
    #
    def reply (workitem)

      if workitem['fei'] == h.fei # apply --> reply

        h.test = attribute(:test)
        h.test = attribute_text if h.test.nil?
        h.test = nil if h.test == ''

        offset = if h.test != nil
          Condition.true?(h.test) ? 0 : 1
        else
          0
        end

        apply_child_if_present(offset, workitem)

      else # reply from a child

        if h.test != nil || Ruote::FlowExpressionId.child_id(workitem['fei']) != 0

          reply_to_parent(workitem)

        else

          apply_child_if_present(
            workitem['fields']['__result__'] == true ? 1 : 2, workitem)
        end
      end
    end

    protected

    def apply_child_if_present (index, workitem)

      if tree_children[index]
        apply_child(index, workitem)
      else
        reply_to_parent(workitem)
      end
    end
  end
end

