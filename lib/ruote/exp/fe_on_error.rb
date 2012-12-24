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
  # Up until ruote 2.3.0, 'on_error' was only an attribute
  #
  #   sequence :on_error => 'error_handler' do
  #     # ...
  #   end
  #
  # This 'on_error' expression makes such definitions possible
  #
  #   sequence do
  #     on_error /unknown participant/ => 'missing_participant'
  #     on_error 'decommission'
  #     # ...
  #   end
  #
  # where errors containing 'unknown participant' in their messages are handled
  # by the participant or subprocess named 'missing participant', while
  # the rest of the errors is handled by the participant or the subprocess
  # named 'decommission'.
  #
  # Speaking of subprocesses, this is also possible
  #
  #   sequence do
  #
  #     on_error /unknown participant/ do
  #       admin :msg => 'there was an unknown participant'
  #     end
  #     on_error do
  #       # decommissioning...
  #     end
  #
  #     # ...
  #   end
  #
  class OnErrorExpression < FlowExpression

    names :on_error

    def apply

      regex = nil
      handler = attribute_text

      if handler == ''
        regex = (attributes.keys - COMMON_ATT_KEYS).first
        handler = attribute(regex)
      end

      if tree.last.size > 0
        regex = handler
        handler = [ 'sequence', {}, Ruote.fulldup(tree.last) ]
      end

      return reply_to_parent(h.applied_workitem) if regex.nil? && handler.nil?
        # nothing to register, let's move on

      par = parent
      oe = par.h.on_error

      if oe.is_a?(String) or Ruote.is_tree?(oe)
        oe = [ nil, oe ]
      end

      oe = Array(par.h.on_error).compact
      oe << [ regex, handler, fei.child_id ]

      par.h.on_error = oe

      if par.do_persist
        reply_to_parent(h.applied_workitem) # success
      else
        apply # try again
      end
    end

    def reply(workitem)

      # never called
    end
  end
end

