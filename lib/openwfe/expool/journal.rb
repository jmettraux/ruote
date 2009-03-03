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


require 'monitor'
require 'fileutils'

require 'openwfe/service'
require 'openwfe/omixins'
require 'openwfe/rudefinitions'
require 'openwfe/flowexpressionid'
require 'openwfe/expool/journal_replay'


module OpenWFE

  #
  # Keeping a replayable track of the events in an OpenWFEru engine
  #
  class Journal < Service

    include MonitorMixin
    include OwfeServiceLocator
    include JournalReplay
    include FeiMixin

    attr_reader :workdir, :donedir

    FREQ = '1m'
      #
      # once per minute, makes sure the buckets are flushed

    def initialize (service_name, application_context)

      super # necessary since we're extending MonitorMixin

      @buckets = {}

      @workdir = get_work_directory + '/journal'
      @donedir = @workdir + '/done'

      FileUtils.makedirs(@donedir) unless File.exist?(@donedir)

      get_expression_pool.add_observer(:all) do |event, *args|
        #ldebug { ":#{event}  for #{args[0].class.name}" }
        queue_event(event, *args)
      end

      @thread_id = get_scheduler.schedule_every(FREQ) do
        flush_buckets()
      end
    end

    #
    # Will flush the journal of every open instance.
    #
    def stop
      get_scheduler.unschedule(@thread_id) if @thread_id
      flush_buckets()
    end

    protected

      #
      # Queues the events before a flush.
      #
      # If the event is a :terminate, the individual bucket will get
      # flushed.
      #
      def queue_event (event, *args)

        #ldebug { "queue_event() :#{event}" }

        return if event == :stop
        return if event == :launch
        return if event == :reschedule

        wfid = extract_fei(args[0]).parent_wfid
          #
          # maybe args[0] could be a FlowExpression instead
          # of a FlowExpressionId instance
        #puts "___#{event}__wfid : #{wfid}"

        e = serialize_event(event, *args)

        bucket = nil

        synchronize do

          bucket = get_bucket(wfid)
          bucket << e

          #ldebug { "queue_event() bucket : #{bucket.object_id}" }

          if event == :terminate

            bucket.flush
            @buckets.delete(wfid)
          end
        end
          #
          # minimizing the sync block

        # TODO : spin that off this thread, to the
        # flush thread...
        #
        if event == :terminate
          if @application_context[:keep_journals] == true
            #
            # 'move' journal to the done/ subdir of journal/
            #
            FileUtils.cp(
              bucket.path,
              @donedir + "/" + File.basename(bucket.path))
          end
          FileUtils.rm bucket.path
        end
      end

      #
      # Makes sure that all the buckets are persisted to disk
      #
      def flush_buckets

        count = 0

        synchronize do

          @buckets.each do |k, v|
            v.flush
            count += 1
          end
          @buckets.clear
        end

        linfo { "flush_buckets() flushed #{count} buckets" } \
          if count > 0
      end

      def get_bucket (wfid)
        @buckets[wfid] ||= Bucket.new(get_path(wfid))
      end

      def serialize_event (event, *args)
        args.insert(0, event)
        args.insert(1, Time.now)
        args.to_yaml
      end

      def get_path (wfid)
        "#{@workdir}/#{wfid.to_s}.journal"
      end

      #
      # for each process instance, there is one bucket holding the
      # events waiting to get written in the journal
      #
      class Bucket

        attr_reader :path, :events

        def initialize (path)
          super()
          @path = path
          @events = []
        end

        def << (event)
          @events << event
        end

        def size
          @events.size
        end
        alias :length :size

        def flush
          File.open(@path, 'a+') do |f|
            @events.each do |e|
              f.puts e
            end
          end
          @events.clear
        end
      end

  end

end
