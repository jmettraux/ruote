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


module OpenWFE

  #
  # Some constants shared by 'cursor', 'loop', 'iterator' and
  # the CommandExpression.
  #
  module CommandConstants

    protected

    A_COMMAND_FIELD = 'command-field'
    F_COMMAND = '__cursor_command__'
    A_DISALLOW = 'disallow'

    C_BACK = 'back'
    C_SKIP = 'skip'

    C_BREAK = 'break'
    C_CANCEL = 'cancel'
    C_OVER = 'over'
    BREAK_COMMANDS = [ C_BREAK, C_CANCEL, C_OVER ]

    C_REWIND = 'rewind'
    C_CONTINUE = 'continue'
    C_JUMP = 'jump'

    A_STEP = 'step'
  end

  #
  # A mixin shared by 'iterator' and 'cursor' ('loop'), simply
  # provides the methods for looking up the "command" (break, skip,
  # rewind, ...) from the workitem and the process.
  #
  module CommandMixin
    include CommandConstants
    include ConditionMixin

    protected

    def determine_command_and_step (workitem)

      #
      # at first, look at the condition attribute

      %w{ break rewind }.each do |cmd|
        return [ cmd, 0 ] \
          if eval_condition("#{cmd}-if", workitem, "#{cmd}-unless")
      end

      #
      # then look at the command field

      command_field = lookup_command_field(workitem)

      command, step = lookup_command(command_field, workitem)

      disallow_list = lookup_disallow(workitem)

      command = nil \
        if disallow_list and disallow_list.include?(command)

      workitem.attributes.delete(command_field)

      [ command, step ]
    end

    private

    #
    # Looks up the value in the command field.
    #
    def lookup_command_field (workitem)

      lookup_attribute(A_COMMAND_FIELD, workitem, :default => F_COMMAND)
    end

    #
    # Returns the command and the step
    #
    def lookup_command (command_field, workitem)

      command = workitem.attributes[command_field]

      return [ nil, 1 ] unless command
        #
        # this corresponds to the "just one step forward" default

      command, step = command.strip.split

      step = step ? step.to_i : 1
      step = -step if command == C_BACK

      [ command, step ]
    end

    #
    # Fetches the value of the 'disallow' cursor attribute.
    #
    def lookup_disallow (workitem)

      lookup_array_attribute(A_DISALLOW, workitem)
    end
  end

  #
  # This class implements the following expressions :  back, break,
  # cancel, continue, jump, rewind, skip.
  #
  # They are generally used inside of a 'cursor' (CursorExpression) or
  # a 'loop' (LoopExpression), they can be used outside, but their result
  # (the value of the field '\_\_cursor_command__' will be used as soon as the
  # flow enters a cursor or a loop).
  #
  # In fact, this expression is only a nice wrapper that sets the
  # value of the field "\_\_cursor_command__" to its name ('back' for example)
  # plus to the 'step' attribute value.
  #
  # For example <skip step="3"/> simply sets the value of the field
  # '\_\_cursor_command__' to 'skip 3'.
  #
  # (The field \_\_cursor_command__ is, by default, read and
  # obeyed by the 'cursor' expression).
  #
  # With Ruby process definitions, you can directly write :
  #
  #   skip 2
  #   jump "0"
  #
  # instead of
  #
  #   skip :step => "2"
  #   jump :step => "0"
  #
  # Likewise, in an XML process definition, you can write
  #
  #   <skip>2</skip>
  #
  # although that might still look lighter (it's longer though) :
  #
  #   <skip step="2"/>
  #
  #
  # About the command themselves :
  #
  # * back : will go back from the number of given steps, 1 by default
  # * break : will exit the cursor (or the loop)
  # * cancel : an alias for 'break'
  # * continue : will exit the cursor, if in a loop, will get back at step 0
  # * jump : will move the cursor (or loop) to an absolute given position (count starts at 0)
  # * rewind : an alias for continue
  # * skip : skips the given number of steps
  #
  #
  # All those command support an 'if' attribute to restrict their execution :
  #
  #   cursor do
  #     go_to_shop
  #     check_prices
  #     _break :if => "${price} > ${f:current_cash}"
  #     buy_stuff
  #   end
  #
  # The 'rif' attribute may be used instead of the 'if' attribute. Its value
  # is some ruby code that, when evaluating to true will let the command
  # be executed.
  #
  #   _skip 2, :rif => "workitem.customers.size % 2 == 0"
  #     #
  #     # skips if the nb of customers is pair
  #
  # Note that the 'rif' attribute will work only if the
  # <tt>:ruby_eval_allowed</tt> parameter is set to true in the engine's
  # application context.
  #
  #   engine.application_context[:ruby_eval_allowed] = true
  #
  class CursorCommandExpression < FlowExpression
    include CommandConstants
    include ConditionMixin

    names :back, :skip, :continue, :break, :cancel, :rewind, :jump, :over

    def apply (workitem)

      conditional = eval_condition(:if, workitem, :unless)
        #
        # for example : <break if="${approved} == true"/>

      if conditional == nil or conditional

        command = @fei.expression_name

        step = lookup_attribute(A_STEP, workitem)
        step = fetch_text_content(workitem) unless step
        step = 1 unless step
        step = Integer(step)

        command = "#{command} #{step}" #if step != 1

        workitem.attributes[F_COMMAND] = command
      end

      reply_to_parent(workitem)
    end
  end

end

