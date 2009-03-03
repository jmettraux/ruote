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


require 'openwfe/expressions/flowexpression'
require 'openwfe/expressions/iterator'
require 'openwfe/expressions/fe_command'


module OpenWFE

  #
  # The 'iterator' expression can be used like that for example :
  #
  #   <iterator
  #     on-value="alice, bob, charles"
  #     to-variable="user-name"
  #   >
  #     <set
  #       field="${user-name} comment"
  #       value="(please fill this field)"
  #     />
  #   </iterator>
  #
  # Within the iteration, the workitem field "\_\_ic__" contains the number
  # of elements in the iteration and the field "\_\_ip__" the index of the
  # current iteration.
  #
  # The 'iterator' expression understands the same cursor commands as the
  # CursorExpression. One can thus exit an iterator or skip steps in it.
  #
  #   iterator :on_value => "alice, bob, charles, doug", to_variable => "v" do
  #     sequence do
  #       participant :variable_ref => "v"
  #       skip 1, :if => "${f:reply} == 'skip next'"
  #     end
  #   end
  #
  # For more information about those commands, see CursorCommandExpression.
  #
  class IteratorExpression < FlowExpression
    include CommandMixin

    names :iterator

    #
    # an Iterator instance that holds the list of values being iterated
    # upon.
    #
    attr_accessor :iterator

    def apply (workitem)

      return reply_to_parent(workitem) if has_no_expression_child

      @iterator = Iterator.new(self, workitem)

      return reply_to_parent(workitem) if @iterator.size < 1

      reply(workitem)
    end

    def reply (workitem)

      command, step = determine_command_and_step(workitem)

      vars = if not command

        @iterator.next workitem

      elsif command == C_BREAK or command == C_CANCEL

        nil

      elsif command == C_REWIND or command == C_CONTINUE

        @iterator.rewind workitem

      elsif command.match "^#{C_JUMP}"

        @iterator.jump workitem, step

      else # C_SKIP or C_BACK

        @iterator.skip workitem, step
      end

      return reply_to_parent(workitem) \
        unless vars

      @children = []

      get_expression_pool.tlaunch_child(
        self,
        raw_children.first,
        @iterator.index,
        workitem,
        :register_child => true,
        :variables => vars)

      #store_itself
        # now done in tlaunch_child()
    end
  end

end

