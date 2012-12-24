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


require 'ruote/exp/commanded'


module Ruote::Exp

  #
  # This class implements the 'cursor' and the 'repeat' (loop) expressions.
  #
  # The cursor expression is a kind of enhanced 'sequence'. Like a sequence
  # it will execute its child expression one by one, sequentially. Unlike a
  # sequence though, it will obey 'commands'.
  #
  #   cursor do
  #     author
  #     reviewer
  #     rewind :if => '${f:not_ok}'
  #     publisher
  #   end
  #
  # In this simplistic example, the process will flow from author to reviewer
  # and back until the reviewer sets the workitem field 'not_ok' to something
  # else than the value 'true'.
  #
  # There are two ways to pass commands to a cursor either directly from
  # the process definition with a cursor command expression, either via
  # the workitem '__command__' [special] field.
  #
  # == cursor commands
  #
  # The commands that a cursor understands are listed here. The most powerful
  # ones are 'rewind' and 'jump'.
  #
  # === rewind
  #
  # Rewinds the cursor up to its first child expression.
  #
  #   cursor do
  #     author
  #     reviewer
  #     rewind :if => '${f:not_ok}'
  #     publisher
  #   end
  #
  # === reset
  #
  # Whereas 'rewind' places the cursor back to the initial step with the current
  # workitem, 'reset' will rewind it and start again but with the workitem
  # as it was when it reached the cursor/repeat.
  #
  # === stop, over & break
  #
  # Exits the cursor.
  #
  #   cursor do
  #     author
  #     reviewer
  #     rewind :if => '${f:review} == fix'
  #     stop :if => '${f:review} == abort'
  #     publisher
  #   end
  #
  # '_break' or 'over' can be used instead of 'stop'.
  #
  # === skip & back
  #
  # Those two commands jump forth and back respectively. By default, they
  # skip 1 child, but they accept a numeric parameter holding the number
  # of children to skip.
  #
  #   cursor do
  #     author
  #     reviewer
  #     rewind :if => '${f:review} == fix'
  #     skip 2 :if => '${f:review} == publish'
  #     reviewer2
  #     rewind :if => '${f:review} == fix'
  #     publisher
  #   end
  #
  # === jump
  #
  # Jump is probably the most powerful of the cursor commands. It allows to
  # jump to a specified expression that is a direct child of the cursor.
  #
  #   cursor do
  #     author
  #     reviewer
  #     jump :to => 'author', :if => '${f:review} == fix'
  #     jump :to => 'publisher', :if => '${f:review} == publish'
  #     reviewer2
  #     jump :to => 'author', :if => '${f:review} == fix'
  #     publisher
  #   end
  #
  # Note that the :to accepts the name of an expression or the value of
  # its :ref attribute or the value of its :tag attribute.
  #
  #   cursor do
  #     participant :ref => 'author'
  #     participant :ref => 'reviewer'
  #     jump :to => 'author', :if => '${f:review} == fix'
  #     participant :ref => 'publisher'
  #   end
  #
  # == cursor command with :ref
  #
  # It's OK to tag a cursor/repeat/loop with the :tag attribute and then
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
  # == cursor command in the workitem
  #
  # The command expressions are merely setting the workitem field '__command__'
  # with an array value [ {command}, {arg} ].
  #
  # For example,
  #
  #   jump :to => 'author'
  #     # is equivalent to
  #   set 'field:__command__' => 'author'
  #
  # It is entirely OK to have a participant implementation that sets __command__
  # by itself.
  #
  #   class Reviewer
  #     include Ruote::LocalParticipant
  #
  #     def consume(workitem)
  #       # somehow review the book
  #       if review == 'bad'
  #         #workitem.fields['__command__'] = [ 'rewind' ] # old style
  #         workitem.command = 'rewind' # new style
  #       else
  #         # let it go
  #       end
  #       reply_to_engine(workitem)
  #     end
  #
  #     def cancel(fei, flavour)
  #       # cancel if review is still going on...
  #     end
  #   end
  #
  # This example uses the Ruote::Workitem#command= method which can be fed
  # strings like 'rewind', 'skip 2', 'jump to author' or the equivalent arrays
  # [ 'rewind' ], [ 'skip', 2 ], [ 'jump', 'author' ].
  #
  #
  # == :break_if / :rewind_if
  #
  # As an attribute of the cursor/repeat expression, you can set a :break_if.
  # It tells the cursor (loop) if it has to break.
  #
  #   cursor :break_if => '${f:completed}' do
  #     participant 'alpha'
  #     participant 'bravo'
  #     participant 'charly'
  #   end
  #
  # If alpha or bravo replies and the field 'completed' is set to true, this
  # cursor will break.
  #
  # :break_unless is accepted. :over_if and :over_unless are synonyms for
  # :break_if and :break_unless respectively.
  #
  # :rewind_if / :rewind_unless behave the same, but the cursor/loop, instead
  # of breaking, is put back in its first step.
  #
  #
  # = repeat (loop)
  #
  # A 'cursor' expression exits implicitely as soon as its last child replies
  # to it.
  # a 'repeat' expression will apply (again) the first child after the last
  # child replied. A 'break' cursor command might be necessary to exit the loop
  # (or a cancel_process, but that exits the whole process instance).
  #
  #   sequence do
  #     repeat do
  #       author
  #       reviewer
  #       _break :if => '${f:review} == ok'
  #     end
  #     publisher
  #   end
  #
  class CursorExpression < CommandedExpression

    names :cursor, :loop, :repeat

    def apply

      move_on
    end

    protected

    # Determines which child expression of the cursor is to be applied next.
    #
    def move_on(workitem=h.applied_workitem)

      position = workitem['fei'] == h.fei ?
        -1 : Ruote::FlowExpressionId.child_id(workitem['fei'])

      position += 1

      com, arg = get_command(workitem)

      return reply_to_parent(workitem) if com == 'break'

      case com
        when 'rewind', 'continue', 'reset' then position = 0
        when 'skip' then position += arg
        when 'jump' then position = jump_to(workitem, position, arg)
      end

      position = 0 if position >= tree_children.size && is_loop?

      if position < tree_children.size

        workitem = h.applied_workitem if com == 'reset'
        apply_child(position, workitem)

      else

        reply_to_parent(workitem)
      end
    end

    # Will return true if this instance is about a 'loop' or a 'repeat'.
    #
    def is_loop?

      name == 'loop' || name == 'repeat'
    end

    # Jumps to an integer position, or the name of an expression
    # or a tag name of a ref name.
    #
    def jump_to(workitem, position, arg)

      pos = Integer(arg) rescue nil

      return pos if pos != nil

      tree_children.each_with_index do |c, i|

        found = [
          c[0],                                      # exp_name
          c[1]['ref'],                               # ref
          c[1]['tag'],                               # tag
          (c[1].find { |k, v| v.nil? } || []).first  # participant 'xxx'
        ].find do |v|
          v ? (dsub(v, workitem) == arg) : false
        end

        if found then pos = i; break; end
      end

      pos ? pos : position
    end
  end
end

