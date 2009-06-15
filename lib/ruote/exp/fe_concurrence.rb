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


require 'ruote/exp/flowexpression'


module Ruote

  class ConcurrenceExpression < FlowExpression

    names :concurrence

    def apply

      @count = attribute(:count).to_i rescue nil
      @count = nil if @count && @count < 1

      @merge = att(:merge, %w[ first last highest lowest ])
      @merge_type = att(:merge_type, %w[ override mix isolate ])
      @remaining = att(:remaining, %w[ cancel forget ])

      @workitems = nil

      tree_children.each_with_index do |c, i|
        apply_child(i, @applied_workitem.dup)
      end
    end

    def reply (workitem)

      return if over?

      if @merge == 'first' || @merge == 'last'
        (@workitems ||= []) << workitem
      else
        (@workitems ||= {})[workitem.fei.expid] = workitem
      end

      if over?
        reply_to_parent
      else
        persist
      end
    end

    protected

    def over?

      # TODO : over_if

      return false unless @workitems

      (@workitems.size >= (@count || tree_children.size))
    end

    def reply_to_parent

      handle_remaining if @children

      super(merge_workitems)
    end

    def merge_workitems

      wis = case @merge
      when 'first'
        @workitems.reverse
      when 'last'
        @workitems
      when 'highest', 'lowest'
        is = @workitems.keys.sort.collect { |k| @workitems[k] }
        @merge == 'highest' ? is.reverse : is
      end

      wis.inject(nil) { |t, wi| merge_workitem(t, wi, @merge_type) }
    end

    def merge_workitem (target, source, type)

      return source if type == 'override'

      source.fields = { source.fei.child_id => source.fields } \
        if target == nil && type == 'isolate'

      return source unless target

      if type == 'mix'
        source.fields.each { |k, v| target.fields[k] = v }
      else # 'isolate'
        target.fields[source.fei.child_id] = source.fields
      end

      target
    end

    def handle_remaining

      m = @remaining == 'cancel' ? :cancel_expression : :forget_expression

      @children.each { |fei| pool.send(m, fei) }
    end
  end
end

