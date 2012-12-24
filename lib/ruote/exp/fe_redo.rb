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
  # Undoes and the redoes (re-applies) an expression identified by a tag.
  #
  #   pdef = Ruote.process_definition do
  #     sequence :tag => 'kilroy' do
  #       alpha
  #       _redo :ref => 'kilroy', :unless => '${f:ok} == true'
  #     end
  #   end
  #
  # will redo at tag 'kilroy' if the field 'ok' is not set to true.
  #
  # (redo is escaped as _redo not to conflict with the "redo" Ruby keyword)
  #
  # Maybe this case is better served by a cursor/rewind combination
  #
  #   pdef = Ruote.process_definition do
  #     cursor do
  #       alpha
  #       rewind :unless => '${f:ok} == true'
  #     end
  #   end
  #
  # (There is a big difference though, a redo will restart with the workitem
  # as it was when the workitem entered the tagged region, while the rewind
  # keeps the workitem as is)
  #
  class RedoExpression < FlowExpression

    names :redo

    def apply

      ref = attribute(:ref) || attribute_text
      tag = ref ? lookup_variable(ref) : nil

      if tag && Ruote.is_a_fei?(tag)

        @context.storage.put_msg(
          'cancel', 'fei' => tag, 're_apply' => { 'workitem' => 'applied' })

        reply_to_parent(h.applied_workitem) unless ancestor?(tag)

      else

        reply_to_parent(h.applied_workitem)
      end
    end

    def reply(workitem)

      # never called
    end
  end
end

