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


require 'ruote/exp/command'


module Ruote::Exp

  #
  # This class gathers the 'skip', 'back', 'jump', 'rewind', 'continue', 'reset'
  # and 'break' expressions which are used inside of the 'cursor' and 'repeat'
  # (loop) expressions.
  #
  # Look at the 'cursor' expression Ruote::Exp::Cursor for a discussion of
  # each of those [sub]expressions.
  #
  # The expression that understand commands are 'cursor', 'repeat' ('loop') and
  # 'iterator'.
  # 'concurrent_iterator' does not understand commands since it fires all its
  # branches when applied.
  #
  # == :ref => 'tag'
  #
  # It's OK to tag a cursor/loop/iterator with the :tag attribute and then
  # point a command to it via :ref :
  #
  #   concurrence do
  #
  #     cursor :tag => 'main' do
  #       author
  #       editor
  #       publisher
  #     end
  #
  #     # meanwhile ...
  #
  #     sequence do
  #       sponsor
  #       rewind :ref => 'main', :if => '${f:stop}'
  #     end
  #   end
  #
  # This :ref technique may also be used with nested cursor/loop/iterator
  # constructs :
  #
  #   cursor :tag => 'main' do
  #     cursor do
  #       author
  #       editor
  #       rewind :if => '${f:not_ok}'
  #       _break :ref => 'main', :if => '${f:abort_everything}'
  #     end
  #     head_of_edition
  #     rewind :if => '${f:not_ok}'
  #     publisher
  #   end
  #
  # this example features two nested cursors. There is a "_break" in the inner
  # cursor, but it will break the main 'cursor' (and thus break the whole
  # review process).
  #
  # :ref works with the 'iterator' expression as well.
  #
  class CommandExpression < FlowExpression

    include CommandMixin

    names :skip, :back, :jump, :rewind, :continue, :break, :stop, :over, :reset

    # Used by FlowExpression when dealing with :on_error or :on_timeout
    #
    REGEXP = Regexp.new("^(#{expression_names.join('|')})( .+)?$")

    def apply

      param = case name
        when 'skip', 'back' then attribute(:step) || attribute_text
        when 'jump' then attribute(:to) || attribute_text
        else nil
      end

      param = Integer(param) rescue param

      command_workitem = Ruote.fulldup(h.applied_workitem)

      set_command(command_workitem, name, param)

      target = parent
      ancestor = true

      if ref = attribute(:ref)

        fei = lookup_variable(ref)

        target = Ruote.is_a_fei?(fei) ?
          Ruote::Exp::FlowExpression.fetch(@context, fei) : nil
        target = target.is_a?(Ruote::Exp::CommandedExpression) ?
          target : nil

        ancestor = target ? ancestor?(target.h.fei) : false

      else

        target = fetch_command_target
      end

      return reply_to_parent(h.applied_workitem) if target.nil?
      return reply_to_parent(command_workitem) if target.h.fei == h.parent_id

      @context.storage.put_msg(
        'reply',
        'fei' => target.h.fei,
        'workitem' => command_workitem,
        'command' => [ name, param ]) # purely indicative for now

      reply_to_parent(h.applied_workitem) unless ancestor
    end

    protected

    # Walks up the expression tree (process instance and returns the first
    # expression that includes the CommandMixin
    #
    # (CommandExpression includes CommandMixin, but since it doesn't have
    # children, no need to 'evince' it)
    #
    def fetch_command_target(exp=parent)

      case exp
        when nil then nil
        when Ruote::Exp::CommandedExpression then exp
        else fetch_command_target(exp.parent)
      end
    end
  end
end

