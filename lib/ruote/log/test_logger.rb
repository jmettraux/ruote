#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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

require 'ruote/log/pretty'


module Ruote

  class TestLogger

    include PrettyLogging

    attr_reader :seen
    attr_reader :log

    attr_accessor :noisy

    def initialize (context)

      @context = context

      if @context.worker
        #
        # this is a worker context, DO log
        #
        @context.worker.subscribe(:all, self)
      #else
        #
        # this is not a worker context, DO NOT log, but be ready to
        # be queried
        #
      end

      @seen = []
      @log = []
      @waiting = []

      @count = -1
      @color = 33
      @noisy = false
    end

    def notify (msg)

      puts(pretty_print(msg)) if @noisy

      @seen << msg
      @log << msg

      check_waiting
    end

    # Blocks until one or more interests are satisfied.
    #
    # interests must be an array of interests. Please refer to
    # Engine#wait_for documentation for allowed values of each interest.
    #
    # If multiple interests are given, wait_for blocks until
    # all of the interests are satisfied.
    #
    # wait_for may only be used by one thread at a time. If one
    # thread calls wait_for and later another thread calls wait_for
    # while the first thread is waiting, the first thread's
    # interests are lost and the first thread will never wake up.
    #
    def wait_for (interests)

      @waiting << [ Thread.current, interests ]

      check_waiting

      Thread.stop if @waiting.find { |w| w.first == Thread.current }

      # and when this thread gets woken up, go on and return __result__

      Thread.current['__result__']
    end

    # Debug only : dumps all the seen events to STDOUTS
    #
    def dump

      @seen.collect { |msg| pretty_print(msg) }.join("\n")
    end

    def color= (c)

      @color = c
    end

    def self.pp (msg)

      @logger ||= TestLogger.new(nil)
      puts @logger.send(:pretty_print, msg)
    end

    protected

    def check_waiting

      return if @waiting.size < 1

      while msg = @seen.shift
        check_msg(msg)
      end
    end

    def check_msg (msg)

      wakeup = []

      @waiting.each do |thread, interests|

        wakeup << thread if matches(interests, msg)
      end

      @waiting.delete_if { |t, i| i.size < 1 }

      wakeup.each do |thread|

        thread['__result__'] = msg
        thread.wakeup
      end
    end

    FINAL_ACTIONS = %w[ terminated ceased error_intercepted ]

    # Checks whether message msg matches any of interests being waited for.
    #
    # Some interests look for actions on particular workflows (e.g.,
    # waiting for some workflow to finish). Other interests are not
    # attached to any particular workflow (e.g., :inactive waits until
    # the engine finishes processing all active and pending workflows)
    # but are still satisfied when actions happen on workflows (e.g.,
    # the last workflow being run finishes).
    #
    # Returns true if all interests being waited for have been satisfied,
    # false otherwise.
    #
    def matches (interests, msg)

      action = msg['action']

      interests.each do |interest|

        satisfied = if interest == :inactive

          (FINAL_ACTIONS.include?(action) && @context.worker.inactive?)

        elsif interest == :empty

          (action == 'terminated' && @context.storage.empty?('expressions'))

        elsif interest.is_a?(Symbol) # participant

          (action == 'dispatch' && msg['participant_name'] == interest.to_s)

        elsif interest.is_a?(Fixnum)

          interests.delete(interest)

          if (interest > 1)
            interests << (interest - 1)
            false
          else
            true
          end

        else # wfid

          (FINAL_ACTIONS.include?(action) && msg['wfid'] == interest)
        end

        interests.delete(interest) if satisfied
      end

      interests.size < 1
    end
  end
end

