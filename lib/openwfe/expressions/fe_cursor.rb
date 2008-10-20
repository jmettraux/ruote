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

require 'openwfe/expressions/condition'
require 'openwfe/expressions/flowexpression'
require 'openwfe/expressions/fe_command'


module OpenWFE

  #
  # The 'cursor' is much like a sequence, but you can go
  # back and forth within it, as it reads the field '\_\_cursor_command__' (or
  # the field specified in the 'command-field' attribute) at each
  # transition (each time it's supposed to move from one child expression to
  # the next).
  #
  #   cursor do
  #     participant "alpha"
  #     skip :step => "2"
  #     participant "bravo"
  #     participant "charly"
  #     set :field => "__cursor_command__", value => "2"
  #     participant "delta"
  #     participant "echo"
  #     skip 2
  #     participant "fox"
  #     #
  #     # in that cursor example, only the participants alpha, charly and
  #     # echo will be handed a workitem
  #     # (notice the last 'skip' with its light syntax)
  #     #
  #   end
  #
  # As you can see, you can directly set the value of the field
  # '\_\_cursor_command__' or use a CursorCommandExpression like 'skip' or
  # 'jump'.
  #
  class CursorExpression < FlowExpression
    include CommandMixin

    names :cursor

    #uses_template

    #
    # the integer identifier for the current loop
    #
    attr_accessor :loop_id

    #
    # what is the index of the child we're currently executing
    #
    attr_accessor :current_child_id

    #--
    # keeping track of the current child (if any)
    #
    #attr_accessor :current_child_fei
    #++


    def apply (workitem)

      new_environment

      @loop_id = 0

      @current_child_id = -1

      reply workitem
    end

    def reply (workitem)

      return reply_to_parent(workitem) \
        if raw_children.size < 1
          #
          # well, currently, no infinite empty loop allowed

      command, step = determine_command_and_step(workitem)

      ldebug { "reply() command is '#{command} #{step}'" }

      if command == C_BREAK or command == C_CANCEL
        return reply_to_parent(workitem)
      end

      if command == C_REWIND or command == C_CONTINUE

        @current_child_id = 0

      elsif command and command.match("^#{C_JUMP}")

        @current_child_id = step
        @current_child_id = 0 if @current_child_id < 0

        @current_child_id = raw_children.length - 1 \
          if @current_child_id >= raw_children.length

      else # C_SKIP or C_BACK

        @current_child_id = @current_child_id + step

        @current_child_id = 0 if @current_child_id < 0

        #if @current_child_id >= @children.length
        if @current_child_id >= raw_children.length

          return reply_to_parent(workitem) unless is_loop

          @loop_id += 1
          @current_child_id = 0
        end
      end

      #template_fei = @children[@current_child_id]
      template = raw_children[@current_child_id]

      #
      # launch the next child as a template

      #@current_child_fei = get_expression_pool.tlaunch_child(
      #  self,
      #  template,
      #  @current_child_id,
      #  workitem,
      #  #false) # not registering child
      #  true) # registering child
        #
        # TODO : check if the register_child switch is still necessary...

      @children.clear if @children
      apply_child(@current_child_id, workitem)

      store_itself
    end

    #--
    # takes care of cancelling the current child if necessary
    #
    #def cancel
    #  cfei = current_child_fei
    #  get_expression_pool.cancel(cfei) if cfei
    #  get_expression_pool.cancel(@current_child_fei) if @current_child_fei
    #  super
    #end
    #++

    #
    # Returns false, the child class LoopExpression does return true.
    #
    def is_loop

      false
    end

  end

  #
  # The 'loop' expression is like 'cursor' but it doesn't exit until
  # it's broken (with 'break' or 'cancel').
  #
  #   <loop>
  #     <participant ref="toto" />
  #     <break if="${f:done} == true" />
  #   </loop>
  #
  # or, in a Ruby process definition :
  #
  #   _loop do
  #     participant "toto"
  #     _break :if => "${f:done} == true"
  #   end
  #
  # (notice the _ (underscores) to distinguish the OpenWFEru expressions
  # from the native Ruby ones).
  #
  class LoopExpression < CursorExpression

    names :loop

    #
    # Returns true as, well, it's a loop...
    #
    def is_loop

      true
    end
  end

end

