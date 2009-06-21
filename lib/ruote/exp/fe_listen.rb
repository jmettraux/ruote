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

  #
  # Listens for activity (incoming or outgoing workitems) on a (set of)
  # participant(s).
  #
  class ListenExpression < FlowExpression

    # TODO : implement where=

    names :listen, :receive

    def apply

      to = attribute(:to) || attribute(:on)
      upon = attribute(:upon) || 'apply'
      @merge = (attribute(:merge) || 'false').to_s

      persist

      tracker.register(
        @fei,
        :workitems,
        upon == 'reply' ? :received : :dispatched,
        :pname => to)

      # block if no children
    end

    def reply (workitem)

      # TODO : where

      wi = @applied_workitem.dup

      if @merge == 'true'
        wi.fields.merge!(workitem.fields)
      elsif @merge == 'override'
        wi.fields = workitem.fields
      #else don't touch
      end

      if tree_children.size > 0
        pool.launch_sub("#{@fei.expid}_0", tree_children[0], self, wi, true)
      else
        reply_to_parent(wi)
      end
    end

    def cancel

      reply_to_parent(@applied_workitem)
    end

    protected

    def reply_to_parent (workitem)

      tracker.unregister(@fei)

      super(workitem)
    end
  end
end

