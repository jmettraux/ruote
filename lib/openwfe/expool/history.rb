#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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


require 'openwfe/service'
require 'openwfe/omixins'
require 'openwfe/rudefinitions'


module OpenWFE

  #
  # A Mixin for history modules
  #
  module HistoryMixin
    include ServiceMixin
    include OwfeServiceLocator

    EXPOOL_EVENTS = [
      :launch, # launching of a [sub]process instance
      :terminate, # process instance terminates
      :cancel, # cancelling an expression
      :error,
      #:reschedule, # at restart, engine reschedules a timed expression
      :stop, # stopping the process engine
      :pause, # pausing a process
      :resume, # resuming a process
      #:launch_child, # launching a process 'fragment'
      #:launch_orphan, # firing and forgetting a sub process
      #:forget, # forgetting an expression (making it an orphan)
      #:remove, # removing an expression
      #:update, # expression changed, reinsertion into storage
      #:apply,
      #:reply,
      #:reply_to_parent, # expression replies to its parent expression
    ]

    def service_init (service_name, application_context)

      super

      @expool_observer = get_expression_pool.add_observer(:all) do |evt, *args|
        handle(:expool, evt, *args)
      end
      @pmap_observer = get_participant_map.add_observer(:all) do |evt, *args|
        handle(:pmap, evt, *args)
      end
    end

    #
    # Mainly, stops observing the expool and the participant map
    #
    def stop

      super

      stop_observing
    end

    #
    # filter events, eventually logs them
    #
    def handle (source, event, *args)

      # filtering expool events

      return if source == :expool and (not EXPOOL_EVENTS.include?(event))

      # normalizing pmap events

      return if source == :pmap and args.first == :after_consume

      if source == :pmap and (not event.is_a?(Symbol))
        return if args.first == :apply
        e = event
        event = args.first
        args[0] = e
      end
        # have to do that swap has pmap uses the participant name as
        # a "channel name"

      # ok, do log now

      log(source, event, *args)
    end

    #
    # the logging job itself
    #
    def log (source, event, *args)

      raise NotImplementedError.new(
        "please provide an implementation of log(source, event, *args)")
    end

    #
    # scans the arguments of the event to determine the fei
    # (flow expression id) related to the event
    #
    def get_fei (args)

      args.each do |a|
        return a.fei if a.respond_to?(:fei)
        return a if a.is_a?(FlowExpressionId)
      end

      nil
    end

    #
    # builds a 'message' string out of the event / args combination
    #
    def get_message (source, event, args)

      args.inject([]) { |r, a|
        r << a if a.is_a?(Symbol) or a.is_a?(String)
        r
      }.join(' ')
    end

    #
    # returns the workitem among the logged args
    #
    def get_workitem (args)

      args.find { |a| a.is_a?(WorkItem) }
    end

    protected

      #
      # Removes the observers on the expool and the participant map
      #
      # (called by stop())
      #
      def stop_observing

        get_expression_pool.remove_observer(@expool_observer)
        get_participant_map.remove_observer(@pmap_observer)
      end
  end

  #
  # A base implementation for InMemoryHistory and FileHistory.
  #
  class History

    include HistoryMixin

    def initialize (service_name, application_context)

      super()

      service_init(service_name, application_context)
    end

    def log (source, event, *args)

      t = Time.now

      msg = "#{t} .#{t.usec} -- #{source.to_s} #{event.to_s}"

      msg << " #{get_fei(args).to_s}" if args.length > 0

      m = get_message(source, event, args)
      msg << " #{m}" if m

      @output << msg + "\n"
    end
  end

  #
  # The simplest implementation, stores the latest 1000 history
  # entries in memory.
  #
  class InMemoryHistory < History

    #
    # the max number of history items stored. By default it's 1000
    #
    attr_accessor :maxsize

    def initialize (service_name, application_context)

      super

      @output = []
      @maxsize = 1008
    end

    #
    # Returns the array of entries.
    #
    def entries
      @output
    end

    def log (source, event, *args)

      super

      while @output.size > @maxsize
        @output.shift
      end
    end

    #
    # Returns all the entries as a String.
    #
    def to_s
      @output.inject('') { |r, entry| r << entry.to_s }
    end
  end

  #
  # Simply dumps the history in the work directory in a file named
  # "history.log"
  # Warning : no fancy rotation or compression implemented here.
  #
  class FileHistory < History

    def initialize (service_name, application_context)

      super

      @output = get_work_directory + '/history.log'
      @output = File.open(@output, 'w+')

      linfo { "new() outputting history to #{@output.path}" }
    end

    def log (source, event, *args)

      super unless @output.closed?
    end

    #
    # Returns a handle on the output file instance used by this
    # FileHistory.
    #
    def output_file
      @output
    end

    #
    # Stops observing the expool and close the output file
    #
    def stop

      stop_observing

      @output.close
    end
  end

end

