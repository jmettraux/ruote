#--
# Copyright (c) 2012, Hartog de Mik <hartog@organisedminds.com>
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
# Made in Germany.
#++

module Ruote
  # an empty base class for observers, just to provide convenience and
  # documentation on how observers operate
  #
  # TODO: Add docs for on_$everything
  # TODO: Rename to ProcessObserver
  #
  class ProcessSubscriber
    attr_reader :context, :options
    def initialize(context, options={})
      @context = context;
      @options = options
    end

    def on_msg(msg)
      return if %w[ participant_registered variable_set ].include? msg['action']

      wfid  = msg['wfid']
      child = false

      if !wfid && msg['parent_id']
        wfid  = msg['parent_id']['wfid']
        child = true

      elsif !wfid && msg['fei']
        wfid = msg['fei']['wfid']

      elsif !wfid
        return
      end

      workitem = begin
        if msg['workitem']
          Ruote::Workitem.new(Rufus::Json.dup(msg['workitem']))
        else
          fetch_workitem(wfid)
        end
      rescue Exception => ex
        Ruote::Workitem.new({})
      end
        

      fields = {
        :wfid     => wfid,
        :workitem => workitem,
        :action   => msg['action'],
        :child    => child,
        :parent   => child
      }

      method = msg['action'].split('_').first

      case msg['action']
      when 'terminated'
        method = 'end'

      when 'error_intercepted'
        error = Kernel.const_get(msg['error']['class']).new(msg['error']['message'])
        error.set_backtrace msg['error']['trace']

        fields[:error] = error

      end

      method = :"on_#{method}"
      if self.respond_to?(method)
        self.send(method, fields)
      end

      return nil
    end

    def fetch_workitem(wfid) # :nodoc:
      workitem = begin
        fetched = @context.dashboard.storage_participant.by_wfid(wfid)
        if fetched && fetched.first
          Ruote::Workitem.new(fetched.first)
        end

      rescue Exception => ex
        nil
      end

      workitem ||= begin
        fetched = @context.dashboard.history.by_wfid(wfid)
        if fetched && fetched.first
          Ruote::Workitem.new(fetched.first['workitem'])
        end

      rescue Exception => ex
        Ruote::Workitem.new({})
      end

      return workitem
    end

    private :fetch_workitem
  end
end