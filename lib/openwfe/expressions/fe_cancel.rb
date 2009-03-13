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


require 'openwfe/expressions/condition'
require 'openwfe/expressions/flowexpression'


module OpenWFE

  #
  # This expression cancels the current process instance. Use with care.
  #
  #   <sequence>
  #     <participant ref="before" />
  #     <cancel-process />
  #     <participant ref="after" />
  #   </sequence>
  #
  # the message "after" will never get printed.
  #
  # Use rather in scenarii like that one :
  #
  #   class TestDefinition1 < ProcessDefinition
  #     def make
  #       process_definition :name => "25_cancel", :revision => "1" do
  #         sequence do
  #           participant "customer"
  #           _cancel_process :if => "${f:no_thanks} == true"
  #           concurrence do
  #             participant "accounting"
  #             participant "logistics"
  #           end
  #         end
  #       end
  #     end
  #   end
  #
  # Note that the expression accepts an "if" attribute.
  #
  class CancelProcessExpression < FlowExpression
    include ConditionMixin

    names :cancel_process, :cancel_flow

    def apply (workitem)

      conditional = eval_condition(:if, workitem, :unless)
        #
        # for example : <cancel-process if="${approved} == false"/>

      return reply_to_parent(workitem) if conditional == false

      #
      # else, do cancel the process

      get_expression_pool.cancel_process(self)

      # no need to reply to parent
    end

    #def reply (workitem)
    #end

  end

end

