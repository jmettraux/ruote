#--
# Copyright (c) 2012-2013, Hartog de Mik <hartog@organisedminds.com>
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
  #
  #   require 'ruote/util/process_observer'
  #
  #   class WebsocketSubscriber < Ruote::ProcessObserver
  #      # override initialize to warm-up a websocket client
  #      def initialize(context, options={})
  #        super
  #        @client = WebsocketClient.new()
  #      end
  #
  #      # tell the listeners that a new process launched
  #      def on_launch(wfid, info)
  #        @client.publish(
  #          "/process/launch",
  #          { :name       => info[:workitem].wf_name,
  #            :wfid       => wfid,
  #            :definition => info[:pdef],
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
  #   # Bind the observer to the Ruote::Dashboard instance
  #   #
  #   dashboard.add_service('websocket_subscriber', WebsocketSubscriber)
  #
  # == Actions
  #
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
  #
  # The methods are called with (wfid[, info])
  #
  # You can provide a method-signature like:
  #
  #   def on_launch(wfid, info)
  #   def on_launch(wfid)
  #
  # ProcessObserver also supports on_pre methods.  You can provide a
  # method-signature like:
  #
  #   def on_pre_launch(wfid, info)
  #   def on_pre_launch(wfid)
  #
  # If the ProcessObserver cannot call the method with the info, it tries
  # to call without info. The info contains a hash of key/value entries.
  #
  # === Info
  #
  # The following info is provided:
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
  #
  # == Error handling
  #
  # If anywhere in your implementation an action raises a StandardError,
  # it is caught by the ProcessObserver and silently ignored.
  #
  class ProcessObserver

    # This error is used when handling an 'error_intercepted' message when we're
    # unable to recreate the original exception by passing the error message as
    # the only argument to the constructor (i.e. the call to 'new').  Some
    # exception classes require different arguments on their constructor.
    #
    class Error < StandardError
      attr_accessor :original_class

      def initialize(original_class, message)
        super(message)
        @original_class = original_class
      end
    end

    attr_reader :context, :options, :filtered_actions

    def initialize(context, options={})

      @filtered_actions = options.delete(:filtered_actions)
      @filtered_actions ||= []
      @filtered_actions |=  %w[dispatched participant_registered variable_set]

      @context = context
      @options = options
    end

    def on_pre_msg(msg)

      route('pre', msg)
    end

    def on_msg(msg)

      route(nil, msg)
    end

    protected

    def route(time, msg)

      action = msg['action']

      return if @filtered_actions.include?(action)

      callback = [ 'on', time, action ].compact.join('_')

      return unless self.respond_to?(callback)

      wfid  = msg['wfid']
      child = false

      if !wfid && msg['parent_id']
        wfid  = msg['parent_id']['wfid']
        child = true
      end

      wfid ||= Ruote.extract_wfid(msg)
      return if !wfid

      info = {
        :workitem  => msg['workitem'] || {},
        :action    => action,
        :child     => child,
        :variables => msg['variables'],
      }

      # change info based on the action

      case action

        when 'launch'

          info[:pdef] = msg['tree']

        when 'cancel'

          info[:flavour] = msg['flavour']

        when 'error_intercepted'

          error_class = Kernel.const_get(msg['error']['class'])
          begin
            error = error_class.new(msg['error']['message'])
          rescue
            error = Ruote::ProcessObserver::Error.new(error_class, msg['error']['message'])
          end
          error.set_backtrace(msg['error']['trace'])

          info[:error] = error

          info[:workitem] = msg['msg']['workitem']
      end

      info[:workitem] = Ruote::Workitem.new(info[:workitem])

      args = [ wfid ]
      args << info if self.method(callback).arity.abs == 2

      self.send(callback, *args)

    rescue
      # swallow any StandardError
    end
  end
end

