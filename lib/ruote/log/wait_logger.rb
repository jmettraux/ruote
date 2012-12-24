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

  # The error raised by WaitLogger#wait_for upon a timeout.
  #
  class LoggerTimeout < StandardError

    def initialize(interests, timeout)

      super("waited for #{interests.inspect}, timed out after #{timeout}s")
    end
  end

  #
  # The logic behind Ruote::Dashboard#wait_for is implemented here.
  #
  # This logger keeps track of the last 56 events. This number can
  # be tweaked via the 'wait_logger_max' storage option
  # (http://ruote.rubyforge.org/configuration.html)
  #
  # One doesn't play directly with this class. It's available only via
  # the Ruote::Dashboard#wait_for and Ruote::Dashboard#noisy=
  #
  # To access the log of processed msgs, look at history services, not
  # at this wait_logger.
  #
  # === options (storage initialization options)
  #
  # wait_logger_max(Integer)::
  #   defaults to 77, max number of recent records to keep track of
  # wait_logger_timeout(Integer)::
  #   defaults to 60 (seconds), #wait_for times out after how many seconds?
  #
  class WaitLogger

    require 'ruote/log/fancy_printing'

    attr_reader :seen
    attr_reader :log

    # When set to true, this logger will spit out the ruote activity
    # happening in this Ruby's runtime ruote worker (if any) to $stdout.
    #
    attr_accessor :noisy

    # The timeout for #wait_for. Defaults to 60 (seconds). When set to
    # number inferior or equal to zero, no timeout will be enforced.
    #
    attr_accessor :timeout

    def initialize(context)

      @context = context

      @seen = []
      @log = []
      @waiting = []

      @count = -1
      @color = 33
      @noisy = false

      @log_max = context['wait_logger_max'] || 77
      @timeout = context['wait_logger_timeout'] || 60 # in seconds

      @check_mutex = Mutex.new
    end

    # The context will call this method for each msg sucessfully processed
    # by the worker.
    #
    def on_msg(msg)

      puts(fancy_print(msg, @noisy)) if @noisy

      return if msg['action'] == 'noop'

      @seen << msg
      @log << msg

      while @log.size > @log_max; @log.shift; end
      while @seen.size > @log_max; @seen.shift; end
    end

    # Returns an array of the latest msgs, but fancy-printed. The oldest
    # first.
    #
    def fancy_log

      @log.collect { |msg| fancy_print(msg) }
    end

    # Debug only : dumps all the seen events to $stdout
    #
    def dump

      @seen.collect { |msg| fancy_print(msg) }.join("\n")
    end

    # Blocks until one or more interests are satisfied.
    #
    # interests must be an array of interests. Please refer to
    # Dashboard#wait_for documentation for allowed values of each interest.
    #
    # If multiple interests are given, wait_for blocks until
    # all of the interests are satisfied.
    #
    # wait_for may only be used by one thread at a time. If one
    # thread calls wait_for and later another thread calls wait_for
    # while the first thread is waiting, the first thread's
    # interests are lost and the first thread will never wake up.
    #
    def wait_for(interests, opts={})

      @waiting << [ Thread.current, interests ]

      Thread.current['__result__'] = nil
      start = Time.now

      to = opts[:timeout] || @timeout
      to = nil if to.nil? || to <= 0

      loop do

        raise(
          Ruote::LoggerTimeout.new(interests, to)
        ) if to && (Time.now - start) > to

        @check_mutex.synchronize { check_waiting }

        break if Thread.current['__result__']

        sleep 0.007
      end

      Thread.current['__result__']
    end

    def color=(c)

      @color = c
    end

    def self.fp(msg)

      @logger ||= TestLogger.new(nil)
      puts @logger.send(:fancy_print, msg)
    end

    protected

    def check_waiting

      while @waiting.any? and msg = @seen.shift

        @waiting.delete_if do |thread, interests|
          if matches(interests, msg)
            thread['__result__'] = msg
            true
          else
            false
          end
        end
      end
    end

    FINAL_ACTIONS = %w[
      terminated ceased error_intercepted
    ]
    ACTIONS = FINAL_ACTIONS + %w[
      launch apply reply
      fail
      dispatch dispatched receive
      cancel dispatch_cancel kill
      pause resume dispatch_pause dispatch_resume
      regenerate
      pause_process resume_process cancel_process kill_process
      reput noop raise
      respark
    ]

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
    def matches(interests, msg)

      action = msg['action']

      interests.each do |interest|

        satisfied = case interest

          when :or_error
            #
            # let's force an immediate reply

            interests.clear if action == 'error_intercepted'

          when :inactive

            (FINAL_ACTIONS.include?(action) && @context.worker.inactive?)

          when :empty

            (action == 'terminated' && @context.storage.empty?('expressions'))

          when Symbol

            (action == 'dispatch' && msg['participant_name'] == interest.to_s)

          when Fixnum

            interests.delete(interest)

            if (interest > 1)
              interests << (interest - 1)
              false
            else
              true
            end

          when Hash

            interest.all? { |k, v|
              k = 'tree.0' if k == 'exp_name'
              Ruote.lookup(msg, k) == v
            }

          when /^[a-z_]+$/

            (action == interest)

          else # wfid

            (FINAL_ACTIONS.include?(action) && msg['wfid'] == interest)
        end

        interests.delete(interest) if satisfied
      end

      if interests.include?(:or_error)
        (interests.size < 2)
      else
        (interests.size < 1)
      end
    end
  end
end

