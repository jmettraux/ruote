#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
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

      reply workitem
    end

    def reply (workitem)

      command, step = determine_command_and_step workitem

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

