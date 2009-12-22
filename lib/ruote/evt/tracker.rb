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


module Ruote

  class Tracker

    def initialize (context)

      @context = context

      if @context.worker
        #
        # this is a worker context, DO log
        #
        @context.worker.subscribe(:all, self)
      #else
        #
        # this is not a worker context, no notifications. BUT
        # honour calls to add_tracker/remove_tracker
        #
      end
    end

    def notify (msg)

      doc = @context.storage.get_trackers

      doc['trackers'].values.each do |tracker|

        t_wfid = tracker['wfid']
        t_action = tracker['action']
        m_wfid = msg['wfid'] || (msg['fei']['wfid'] rescue nil)

        next if t_wfid && t_wfid != m_wfid
        next if t_action && t_action != msg['action']

        next unless does_match?(msg, tracker['conditions'])

        m = tracker['msg']

        @context.storage.put_msg(
          m.delete('action'),
          m.merge!('workitem' => msg['workitem']))
      end
    end

    def does_match? (msg, conditions)

      conditions.each do |k, v|
        val = msg[k]
        return false unless val && val.match(v)
      end

      true
    end

    def add_tracker (wfid, action, fei, conditions, msg, doc=nil)

      doc ||= @context.storage.get_trackers

      doc['trackers'][Ruote.to_storage_id(fei)] =
        { 'wfid' => wfid,
          'action' => action,
          'fei' => fei,
          'conditions' => conditions,
          'msg' => msg }

      r = @context.storage.put(doc)

      add_tracker(wfid, action, fei, msg, r) if r
        # the put failed, have to redo the work
    end

    def remove_tracker (fei, doc=nil)

      doc ||= @context.storage.get_trackers

      doc['trackers'].delete(Ruote.to_storage_id(fei))

      r = @context.storage.put(doc)

      remove_tracker(fei, r) if r
        # the put failed, have to redo the work
    end
  end
end

