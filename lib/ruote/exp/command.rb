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


module Ruote::Exp

  #
  # Commands are understood by the cursor, loop and iterator expressions.
  #
  module CommandMixin

    # Field name '__command__', where one can place a command.
    #
    F_COMMAND = '__command__'

    # break_if, break_unless, rewind_if, rewind_unless, ...
    #
    ATT_COMMANDS = %w[ break rewind reset over stop ]

    protected

    # TODO : :ignore_workitem / :disallow => 'workitem' thing ?

    def get_command(workitem)

      command, step = workitem['fields'].delete(F_COMMAND)
      command, step = lookup_attribute_command(workitem) unless command
      command = 'break' if command == 'over' || command == 'stop'

      step = 1 if step == ''

      return nil if command == nil

      if command == 'back'
        command = 'skip'
        step = step ? -step : -1
      elsif command == 'skip'
        step ||= 1
      end

      [ command, step ]
    end

    def set_command(workitem, command, step=nil)

      workitem['fields'][F_COMMAND] = [ command, step ]
    end

    def lookup_attribute_command(workitem)

      lookup_att_com('if', workitem) || lookup_att_com('unless', workitem)
    end

    def lookup_att_com(dir, workitem)

      ATT_COMMANDS.each do |com|

        c = attribute("#{com}_#{dir}", workitem)

        next unless c

        c = Condition.true?(c)

        return [ com, nil ] if (dir == 'if' && c) || (dir == 'unless' && ( ! c))
      end

      nil
    end
  end
end

