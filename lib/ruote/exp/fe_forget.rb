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
  # Forgets all of its children.
  #
  # This expression is somehow deprecated in favour of the :forget attribute
  # that any expression understands.
  #
  #   sequence do
  #     participant 'alpha'
  #     forget do
  #       sequence do
  #         participant 'bravo'
  #         participant 'charly'
  #       end
  #     end
  #     participant 'delta'
  #   end
  #
  # In this example above, the flow goes from alpha to bravo and delta. The
  # bravo-charly segment is independent of the main process flow. Charly's
  # reply will be forgotten.
  #
  # Now the equivalent process definition, but using the :forget attribute :
  #
  #   sequence do
  #     participant 'alpha'
  #     sequence :forget => true do
  #       participant 'bravo'
  #       participant 'charly'
  #     end
  #     participant 'delta'
  #   end
  #
  # This expression can be useful for fire-and-forget 'parallelism'
  # in processes.
  #
  #
  # == multi forget
  #
  # Forget multiple children at once.
  #
  #   forget do
  #     alice :task => 'take out garbage'
  #     bob :task => 'clean living room'
  #   end
  #
  # The forget expression will reply immediately to its parent expression, it
  # will thus not be cancellable (neither the children will be cancellable).
  #
  #
  # == forget vs lose vs flank
  #
  # forget : replies to parent expression immediately, is not cancellable
  # (not reachable).
  #
  # lose : never replies to the parent expression, is cancellable.
  #
  # flank : immediately replies to the parent expression, is cancellable.
  #
  class ForgetExpression < FlowExpression

    names :forget

    def apply

      tree_children.each_with_index do |t, index|
        apply_child(index, Ruote.fulldup(h.applied_workitem), true)
      end

      reply_to_parent(h.applied_workitem)
    end

    def reply(workitem)

      # never gets called
    end
  end
end

