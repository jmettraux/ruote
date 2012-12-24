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


module Ruote

  #
  # The tracker service is used by the "listen" expression. This services
  # sees all the msg processed by a worker and triggers any
  # listener interested in a particular msg.
  #
  # Look at the ListenExpression for more details.
  #
  class Tracker

    def initialize(context)

      @context = context
    end

    # The worker calls this method via the context before each msg gets
    # processed.
    #
    def on_pre_msg(msg)

      on_message(true, msg)
    end

    # The worker calls this method via the context after each successful
    # msg processing.
    #
    def on_msg(msg)

      on_message(false, msg)
    end

    # Adds a tracker (usually when a 'listen' expression gets applied).
    #
    # The tracker_id may be nil (one will then get generated).
    #
    # Returns the tracker_id.
    #
    def add_tracker(wfid, action, tracker_id, conditions, msg)

      tracker_id ||= [
        'tracker', wfid, action,
        Ruote.generate_subid(conditions.hash.to_s + msg.hash.to_s)
      ].collect(&:to_s).join('_')

      conditions =
        conditions && conditions.remap { |(k, v), h| h[k] = Array(v) }

      doc = @context.storage.get_trackers

      doc['trackers'][tracker_id] =
        { 'wfid' => wfid,
          'action' => action,
          'id' => tracker_id,
          'conditions' => conditions,
          'msg' => msg }

      r = @context.storage.put(doc)

      add_tracker(wfid, action, tracker_id, conditions, msg) if r
        # the put failed, have to redo the work

      tracker_id
    end

    # Removes a tracker (usually when a 'listen' expression replies to its
    # parent expression or is cancelled).
    #
    def remove_tracker(fei_sid_or_id, wfid=nil)

      tracker_id =
        if fei_sid_or_id.is_a?(String)
          fei_sid_or_id
        else
          Ruote.to_storage_id(fei_sid_or_id)
        end

      remove([ tracker_id ], wfid)
    end

    protected

    # Removes a set of tracker ids and updated the tracker document.
    #
    def remove(tracker_ids, wfid)

      return if tracker_ids.empty?

      doc ||= @context.storage.get_trackers(wfid)

      return if (doc['trackers'].keys & tracker_ids).empty?

      doc['wfid'] = wfid
        # a little helper for some some storage implementations like ruote-swf
        # they need to know what workflow execution is targetted.

      tracker_ids.each { |ti| doc['trackers'].delete(ti) }
      r = @context.storage.put(doc)

      remove(tracker_ids, wfid) if r
        # the put failed, have to redo the work
    end

    # The method behind on_pre_msg and on_msg. Filters msgs against trackers.
    # Triggers trackers if there is a match.
    #
    def on_message(pre, message)

      m_wfid = message['wfid'] || (message['fei']['wfid'] rescue nil)
      m_error = message['error']

      m_action = message['action']
      m_action = "pre_#{m_action}" if pre

      msg = m_action == 'error_intercepted' ? message['msg'] : message

      ids_to_remove = []

      trackers.each do |tracker_id, tracker|

        # filter msgs

        t_wfid = tracker['wfid']
        t_action = tracker['action']

        next if t_wfid && t_wfid != m_wfid
        next if t_action && t_action != m_action

        next unless does_match?(message, tracker['conditions'])

        if tracker_id == 'on_error' || tracker_id == 'on_terminate'

          fs = msg['workitem']['fields']

          next if m_action == 'error_intercepted' && fs['__error__']
          next if m_action == 'terminated' && (fs['__error__'] || fs['__terminate__'])
        end

        # remove the message post-trigger?

        ids_to_remove << tracker_id if tracker['msg'].delete('_auto_remove')

        # OK, have to pull the trigger (or alter the message) then

        if pre && tracker['msg']['_alter']
          alter(m_wfid, m_error, m_action, msg, tracker)
        else
          trigger(m_wfid, m_error, m_action, msg, tracker)
        end
      end

      remove(ids_to_remove, nil)
    end

    # Alters the msg, only called in "pre" mode.
    #
    def alter(m_wfid, m_error, m_action, msg, tracker)

      case tracker['msg'].delete('_alter')
        when 'merge' then msg.merge!(tracker['msg'])
        #else ...
      end
    end

    # Prepares the message that gets placed on the ruote msg queue.
    #
    def trigger(m_wfid, m_error, m_action, msg, tracker)

      t_action = tracker['action']
      tracker_id = tracker['id']

      m = Ruote.fulldup(tracker['msg'])

      action = m.delete('action')

      m['wfid'] = m_wfid if m['wfid'] == 'replace'
      m['wfid'] ||= @context.wfidgen.generate

      m['workitem'] = msg['workitem'] if m['workitem'] == 'replace'

      if t_action == 'error_intercepted'
        m['workitem']['fields']['__error__'] = m_error
      elsif tracker_id == 'on_error' && m_action == 'error_intercepted'
        m['workitem']['fields']['__error__'] = m_error
      elsif tracker_id == 'on_terminate' && m_action == 'terminated'
        m['workitem']['fields']['__terminate__'] = { 'wfid' => m_wfid }
      end

      if m['variables'] == 'compile'
        fexp = Ruote::Exp::FlowExpression.fetch(@context, msg['fei'])
        m['variables'] = fexp ? fexp.compile_variables : {}
      end

      @context.storage.put_msg(action, m)
    end

    # Returns the trackers currently registered.
    #
    # Note: this is called from on_pre_msg and on_msg, hence two times
    # for a single msg. We trust the storage implementation to cache it
    # for us.
    #
    def trackers

      @context.storage.get_trackers['trackers']
    end

    # Given a msg and a hash of conditions, returns true if the msg
    # matches the conditions.
    #
    def does_match?(msg, conditions)

      return true unless conditions

      conditions.each do |k, v|

        return false unless Array(v).find do |vv|

          # the Array(v) is for backward compatibility, although newer
          # track conditions are already stored as arrays.

          vv = Ruote.regex_or_s(vv)

          val = case k

            when 'class' then msg['error']['class']
            when 'message' then msg['error']['message']

            else Ruote.lookup(msg, k)
          end

          val && (vv.is_a?(Regexp) ? vv.match(val) : vv == val)
        end
      end

      true
    end
  end
end

