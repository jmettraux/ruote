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

  # A base class for process observers, just to provide convenience. It
  # (heavily) sugar coats the Ruote::Observer and translate the messages into
  # actions. Each such action is provided with pre-distilled information
  # relevant for processes.
  #
  # == Example implementation
  #   class WebsocketSubscriber < Ruote::ProcessObserver
  #      # override initialize to warm-up a websocket client
  #      def initialize(context, options={})
  #        super
  #        @client = WebsocketClient.new()
  #      end
  #
  #      # tell the listeners that a new process launched
  #      def on_launch(wfid, opts)
  #        @client.publish(
  #          "/process/launch",
  #          { :name       => opts[:workitem].wf_name,
  #            :wfid       => wfid,
  #            :definition => opts[:pdef],
  #          }
  #        )
  #      end
  #
  #      # tell the listeners that a new process ended
  #      def on_end(wfid)
  #        @client.publish("/process/#{wfid}", { :end => true })
  #      end
  #   end
  #
  # == Actions
  # The ProcessObserver adheres closely to the message actions, it calls the
  # following methods:
  #
  # on_launch::            When a process or sub-process starts
  # on_terminated::        When a process ends
  # on_error_intercepted:: When an error was intercepted
  # on_cancel::            When a process or sub-process was canceled
  # on_dispatch::          When a participant is dispatched
  # on_receive::           Whenever a workitem is received
  #
  # And others, but if you are interested in those; you might be better of
  # using the more low-level Ruote::Observer
  #
  # == Arguments
  # The methods are called with (wfid[, options])
  #
  # You can provide a method-signature like:
  #
  #   def on_launch(wfid, options)
  #   def on_launch(wfid)
  #
  # If the ProcessObserver cannot call the method with the options, it tries
  # to call without options
  #
  # === Options
  # The following options are provided:
  #
  # :workitem::  The workitem, if available
  # :action::    The original name of the action
  # :child::     Boolean; This is an event of a child, or sub-flow
  # :error::     The intercepted error (only provided with
  #              #on_error_intercepted)
  # :pdef::      The (sub-)process definition (only provided with #on_launch)
  # :variables:: The process variables, if available
  # :flavour::   The flavour of canceling (only on_cancel)
  #
  # == Error handling
  #
  # If anywhere in your implementation an action raises an error, it is caught
  # by the ProcessObserver and silently ignored.
  #
  class ProcessObserver

    attr_reader :context, :options, :filtered_actions

    def initialize(context, options={})
      @filtered_actions = options.delete(:filtered_actions)
      @filtered_actions ||= []
      @filtered_actions |=  %w[dispatched participant_registered variable_set]

      @context = context
      @options = options
    end

    def on_msg(msg) # :nodoc:

      return if @filtered_actions.include? msg['action']

      wfid  = msg['wfid']
      child = false

      if !wfid && msg['parent_id']
        wfid  = msg['parent_id']['wfid']
        child = true
      end

      wfid ||= Ruote.extract_wfid(msg)
      return if !wfid

      workitem = begin
        if msg['workitem']
          Ruote::Workitem.new(Rufus::Json.dup(msg['workitem']))
        else
          Ruote::Workitem.new({})
        end
      rescue
        Ruote::Workitem.new({})
      end

      data = {
        :workitem  => workitem,
        :action    => msg['action'],
        :child     => child,
        :variables => msg['variables'],
      }

      # the prelimenary method name
      method = msg['action'].split('_').first

      # change method or fields based on the action
      case msg['action']
      when 'launch'
        data[:pdef] = msg['tree']

      when 'cancel'
        data[:flavour] = msg['flavour']

      when 'error_intercepted'
        error = Kernel.const_get(msg['error']['class']).new(msg['error']['message'])
        error.set_backtrace msg['error']['trace']

        data[:error] = error
        method = msg['action']
      end

      callback = "on_#{method}"
      if self.respond_to?(callback)
        args = [ wfid ]
        args << data if self.method(callback).arity.abs == 2

        self.send(callback, *args)
      end

      return
    rescue
      return
    end

  end
end
