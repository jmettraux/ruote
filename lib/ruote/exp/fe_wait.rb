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
  # Waits (sleeps) for a given period of time before resuming the flow.
  #
  #   sequence do
  #     accounting :task => 'invoice'
  #     wait '30d' # 30 days
  #     accounting :task => 'check if customer paid'
  #   end
  #
  # '_sleep' is also OK
  #
  #   _sleep '7d10h' # 7 days and 10 hours
  #
  # (the underscore prevents collision with Ruby's sleep method)
  #
  # == :for and :until
  #
  # 'wait' accepts as well :
  #
  #   wait :for => '30d' # wait for 30 days
  #   wait :until => '2011/12/10 12:00:00' # any parseable date/time format
  #
  class WaitExpression < FlowExpression

    names :wait, :sleep

    def apply

      h.for = attribute(:for) || attribute_text
      h.until = attribute(:until)

      h.at = h.for
      h.at = h.until if h.at == ''

      return reply_to_parent(h.applied_workitem) unless h.at

      h.schedule_id = @context.storage.put_schedule(
        'at',
        h.fei,
        h.at,
        'action' => 'reply',
        'fei' => h.fei,
        'workitem' => h.applied_workitem)

      persist_or_raise
    end

    #--
    # no need to override, simply reply to parent expression.
    #def reply (workitem)
    #end
    #++
  end
end

