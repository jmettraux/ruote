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
  # Undoes (cancels) another expression referred by its tag.
  #
  #   pdef = Ruote.process_definition do
  #     concurrence do
  #       alpha :tag => 'kilroy'
  #       undo :ref => 'kilroy'
  #     end
  #   end
  #
  # This example is rather tiny, but it shows a process branch (undo) cancelling
  # another (alpha).
  #
  # == cancel
  #
  # This expression is aliased to 'cancel'
  #
  #   cancel :ref => 'invoicing_stage'
  #
  # == a bit shorter
  #
  # It's OK to shorten
  #
  #   cancel :ref => 'invoicing_stage'
  #
  # to
  #
  #   cancel 'invoicing_stage'
  #
  # == kill
  #
  #   kill :ref => 'invoicing stage'
  #
  # will cancel the target expression and bypass any on_cancel handler set for
  # it.
  #
  #   concurrence do
  #     sequence :tag => 'x', :on_cancel => 'y' do
  #       # ...
  #     end
  #     sequence do
  #       # ...
  #       kill 'x'
  #     end
  #   end
  #
  # In this example the :on_cancel => 'y' will get ignored if kill 'x' kicks
  # in.
  #
  class UndoExpression < FlowExpression

    names :undo, :cancel, :kill

    def apply

      ref = attribute(:ref) || attribute_text
      ref = ref.strip if ref

      tag = (ref && ref != '') ? lookup_variable(ref) : nil

      @context.storage.put_msg(
        'cancel',
        'fei' => tag,
        'flavour' => self.name == 'kill' ? 'kill' : nil
      ) if Ruote.is_a_fei?(tag)

      reply_to_parent(h.applied_workitem)
    end

    def reply(workitem)

      # never called
    end
  end
end

