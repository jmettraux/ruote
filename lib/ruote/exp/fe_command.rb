#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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
  # This class gathers the 'skip', 'back', 'jump', 'rewind', 'continue' and
  # 'break' expressions which are used inside of the 'cursor' and 'repeat'
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

    names :skip, :back, :jump, :rewind, :continue, :break

    def apply

      param = case name
      when 'skip', 'back' then attribute(:step) || attribute_text
      when 'jump' then attribute(:to) || attribute_text
      else nil
      end

      param = Integer(param) rescue param

      set_command(@applied_workitem, name, param)

      persist
        # to keep track of the command set in the @applied_workitem fields

      target = parent
      ancestor = true

      if ref = attribute(:ref)

        fei = lookup_variable(ref)

        target = fei.is_a?(Ruote::FlowExpressionId) ? expstorage[fei] : nil
        target = target.respond_to?(:set_command) ? target : nil

        ancestor = target ? ancestor?(target.fei) : false

      else

        target = fetch_command_target
      end

      if target.nil? || target.fei == @parent_id

        reply_to_parent(@applied_workitem)
        return
      end

      target.set_command_workitem(@applied_workitem)

      child_fei = target.children.first

      pool.cancel_expression(child_fei, nil) if child_fei
        # flavour is nil, regular cancel

      reply_to_parent(@applied_workitem) if not ancestor
    end

    # Necessary in case of 'pass_command_directly'
    #
    def cancel (flavour)

      reply_to_parent(@applied_workitem)
    end

    protected

    # Walks up the expression tree (process instance and returns the first
    # expression that includes the CommandMixin
    #
    # (CommandExpression includes CommandMixin, but since it doesn't have
    # children, no need to 'evince' it)
    #
    def fetch_command_target (exp=parent)

      return nil \
        unless exp

      return exp \
        if exp.class.included_modules.include?(Ruote::Exp::CommandMixin)

      fetch_command_target(exp.parent)
    end
  end
end

