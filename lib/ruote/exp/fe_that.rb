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

require 'ruote/exp/fe_sequence'


module Ruote::Exp

  #
  # The 'that' and the 'of' expressions are used in conjuction with
  # the 'given' expression (GivenExpression).
  #
  # In can be used 'standalone', it thus becomes then merely an 'if'.
  #
  # The children of the that/of are executed if the condition evaluates to
  # true. The children are executed one by one, as if the that/of were
  # a sequence.
  #
  #   given '${status}' do
  #     that '${location} == CH' do
  #       set 'f:bank' => 'UBS'
  #       subprocess 'buy_chocolate'
  #     end
  #     of 'ready' do
  #       participant 'saleshead', :msg => 'customer ready'
  #       participant 'salesman', :task => 'visiter customer'
  #     end
  #     of 'over' do
  #       participant 'manager', :msg => 'process over'
  #     end
  #   end
  #
  # (Yes, I know, it's a poor example).
  #
  class ThatExpression < SequenceExpression

    names :that, :of

    def reply(workitem)

      if workitem['fei'] == h.fei # apply --> reply

        cond = attribute(:t) || attribute(:test) || attribute_text

        if name == 'of'
          comparator = cond.match(/^\s*\/.*\/\s*$/) ? '=~' : '=='
          cond = "#{workitem['fields']['__given__']} #{comparator} #{cond}"
        end

        h.result = Condition.true?(cond)

        if h.result
          apply_child(0, workitem)
        else
          reply_to_parent(workitem)
        end

      else # reply from child

        super
      end
    end

    def reply_to_parent(workitem)

      workitem['fields']['__result__'] = h.result
      super
    end
  end
end

