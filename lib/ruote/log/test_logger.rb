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

#require 'ruote/util/tree'


module Ruote

  class TestLogger

    NOTEWORTHY = %w[
      terminated
      ceased
      cancelled killed
      error_intercepted
      receive
      dispatch
      cancel
    ]

    attr_reader :noteworthy
    attr_reader :log

    def initialize (context)

      @context = context

      if @context.respond_to?(:worker)
        #
        # this is a worker context, DO log
        #
        @context.worker.subscribe(:all, :all, self)
      else
        #
        # this is not a worker context, DO NOT log, but be ready to
        # be queried
        #
      end

      @noteworthy = []
      @log = []
      @waiting = nil

      # NOTE
      # in case of troubles, why not have the wait_for has an event ?
    end

    def notify (event)

      #@context.storage.put(event.merge('type' => 'archived_task'))

      pretty_print(event) if @context[:noisy]

      if NOTEWORTHY.include?(event['action'])
        @noteworthy << event
        @log << event
      end

      check_waiting
    end

    def wait_for (interest)

      @waiting = [ Thread.current, interest ]

      check_waiting

      Thread.stop if @waiting
    end

    protected

    def check_waiting

      return unless @waiting

      thread, interest = @waiting

      over = false

      while event = @noteworthy.shift
        over = if interest.is_a?(Symbol) # participant
          (event['action'] == 'dispatch' &&
           event['participant_name'] == interest.to_s)
        else # wfid
          event['wfid'] == interest
        end
        break if over
      end

      if over
        @waiting = nil
        thread.wakeup
      end
    end

    def pretty_print (event)

      fei = event['fei']
      depth = fei ? fei['expid'].split('_').size : 0

      i = fei ?
        [ fei['wfid'], fei['sub_wfid'], fei['expid'] ].join(' ') :
        event['wfid']

      rest = event.dup
      %w[
        _id type action
        fei wfid workitem variables
      ].each { |k| rest.delete(k) }

      puts "#{'  ' * depth}#{event['action'][0, 2]} #{i} #{rest.inspect}"
    end
  end
end

