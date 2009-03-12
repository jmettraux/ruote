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
  # == 'rewind-if' / 'break-if'
  #
  # Since Ruote 0.9.20 (december 2008), the 'cursor' (or 'loop') expression
  # accepts an 'rewind-if' or 'break-if' attribute.
  #
  #   Test0 = OpenWFE.process_definition :name => 'ft_9c', :revision => '0' do
  #     cursor :rewind_if => "${f:restart}" do
  #       alpha
  #       bravo
  #       charly
  #     end
  #   end
  #
  # This process will be rewound (jump back to 'alpha') if alpha, bravo or
  # charly set the field 'restart' to 'true'.
  # (remember to reset the field if you don't want to rewind/break again and
  # again...)
  #
  # Note that 'rewind-unless' and 'break-unless' are understood as well.
  #
  class CursorExpression < FlowExpression
    include CommandMixin

    names :cursor

    #
    # the integer identifier for the current loop
    #
    attr_accessor :loop_id

    #
    # what is the index of the child we're currently executing
    #
    attr_accessor :current_child_id


    def apply (workitem)

      new_environment

      @loop_id = 0
      @current_child_id = -1

      reply(workitem)
    end

    def reply (workitem)

      return reply_to_parent(workitem) if raw_children.size < 1
        #
        # well, currently, no infinite empty loop allowed

      command, step = determine_command_and_step(workitem)

      #ldebug { "reply() command is '#{command} #{step}'" }

      return reply_to_parent(workitem) if BREAK_COMMANDS.include?(command)

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

        if @current_child_id >= raw_children.length

          return reply_to_parent(workitem) unless is_loop

          @loop_id += 1
          @current_child_id = 0
        end
      end

      template = raw_children[@current_child_id]

      #
      # launch the next child as a template

      @children.clear if @children
      apply_child(@current_child_id, workitem)

      #store_itself
        # now done in apply_child()
    end

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

    names :loop, :repeat

    #
    # Returns true as, well, it's a loop...
    #
    def is_loop

      true
    end
  end

end

