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
  # 're-opening' the FlowExpression class to add timers related methods.
  #
  class FlowExpression

    protected

    # Reads the :timeout and :timers attributes and schedule as necessary.
    #
    def consider_timers

      h.has_timers = (attribute(:timers) || attribute(:timeout)) != nil
        # to enforce pdef defined timers vs participant defined timers

      timers = (attribute(:timers) || '').split(/,/)

      if to = attribute(:timeout)
        timers << "#{to}: timeout" unless to.strip == ''
      end

      schedule_timers(timers)
    end

    # Used by #consider_timers and
    # ParticipantExpression#consider_participant_timers
    #
    # Takes care of registering the timers/timeout for an expression.
    #
    def schedule_timers(timers)

      timers.each do |t|

        after, action = if t.is_a?(String)
          i = t.rindex(':')
          [ t[0..i - 1], t[i + 1..-1] ]
        else
          t
        end

        after = after.strip
        action = action.strip

        next if after == ''

        msg = case action

          when 'timeout', 'undo', 'pass'

            { 'action' => 'cancel',
              'fei' => h.fei,
              'flavour' => action == 'timeout' ? 'timeout' : nil }

          when 'redo', 'retry'

            { 'action' => 'cancel',
              'fei' => h.fei,
              're_apply' => true }

          when /^err(or)?( *.+)?$/

            message = if $~[2]
              $~[2].to_s.strip
            else
              "timer induced error (\"#{after}: #{action}\")"
            end

            { 'action' => 'cancel',
              'fei' => h.fei,
              're_apply' => { 'tree' => [ 'error', { message => nil }, [] ] } }

          when CommandExpression::REGEXP

            { 'action' => 'cancel',
              'fei' => h.fei,
              're_apply' => {
                'tree' => [
                  $~[1], { $~[2].split(' ').last.to_s => nil }, [] ] } }

          else

            { 'action' => 'apply',
              'wfid' => h.fei['wfid'],
              'expid' => h.fei['expid'],
              'parent_id' => h.fei,
              'flanking' => true,
              'tree' => [ action, {}, [] ],
              'workitem' => h.applied_workitem }
        end

        (h.timers ||= []) <<
          [ @context.storage.put_schedule('at', h.fei, after, msg), action ]
      end
    end
  end
end

