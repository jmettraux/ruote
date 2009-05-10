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
  # Encapsulating process error information.
  #
  # Instances of this class may be used to replay_at_error
  #
  class ProcessError

    # When did the error occur.
    #
    attr_accessor :date
    attr_accessor :fdate

    # The FlowExpressionId instance uniquely pointing at the expression
    # which 'failed'.
    #
    attr_accessor :fei

    # Generally something like :apply or :reply
    #
    attr_accessor :message

    # The workitem accompanying the message (apply(workitem) /
    # reply (workitem)).
    #
    attr_accessor :workitem

    # The String stack trace of the error.
    #
    attr_accessor :stacktrace

    alias :backtrace :stacktrace

    # The error class (String) of the top level error
    #
    attr_accessor :error_class

    def initialize (*args)

      if args.size > 0

        @date = Time.now
        @fdate = @date.to_f
        @fei, @message, @workitem, @error_class, @stacktrace = args
      end
    end

    # Returns the parent workflow instance id (process id) of this
    # ProcessError instance.
    #
    def wfid

      @fei.parent_wfid
    end

    alias :parent_wfid :wfid

    # Produces a human readable version of the information in the
    # ProcessError instance.
    #
    def to_s
      s = ''
      s << "-- #{self.class.name} --\n"
      s << "   date : #{@date}\n"
      s << "   fdate : #{@fdate}\n"
      s << "   fei : #{@fei}\n"
      s << "   message : #{@message}\n"
      s << "   workitem : ...\n"
      s << "   error_class : #{@error_class}\n"
      s << "   stacktrace : #{@stacktrace[0, 80]}\n"
      s
    end

    # Returns a hash version of this process error
    #
    def hash

      "#{@fei.to_s} #{@fdate}".hash
    end

    # Returns true if the other instance is a ProcessError and is the
    # same error as this one.
    #
    def == (other)

      other.is_a?(OpenWFE::ProcessError) ? (hash == other.hash) : false
    end
  end

  #
  # This is a base class for all error journal, don't instantiate,
  # work rather with InMemoryErrorJournal (only for testing envs though),
  # or YamlErrorJournal.
  #
  class ErrorJournal < Service

    include OwfeServiceLocator
    include FeiMixin

    def initialize (service_name, application_context)

      super

      @observers = []

      @observers << get_expression_pool.add_observer(:error) do |evt, *args|
        #
        # logs each error occurring in the expression pool

        begin

          record_error(OpenWFE::ProcessError.new(*args))

        rescue Exception => e
          lwarn { "(failed to record error : #{e})\n#{e.backtrace.join("\n")}" }
          lwarn { "*** process error : \n#{args.join("\n")}" }
        end
      end

      @observers << get_expression_pool.add_observer(:terminate) do |evt, *args|
        #
        # removes error log when a process terminates

        fei = args[0].fei

        remove_error_log(fei.wfid) if fei.is_in_parent_process?
      end
    end

    # Stops this journal, takes care of 'unobserving' the expression pool
    #
    def stop

      super

      @observers.each { |o| get_expression_pool.remove_observer(o) }
    end

    # Returns true if the given wfid (or fei) (process instance id)
    # has had errors.
    #
    def has_errors? (wfid)

      get_error_log(wfid).size > 0
    end

    # Takes care of removing an error from the error journal and
    # they replays its process at that point.
    #
    def replay_at_error (error)

      error = error.as_owfe_error if error.respond_to?(:as_owfe_error)

      remove_errors(
        error.fei.parent_wfid,
        error)

      get_workqueue.push(
        get_expression_pool,
        :do_apply_reply,
        error.message,
        error.fei,
        error.workitem)
    end

    # A utility method : given a list of errors, will make sure that for
    # each flow expression only one expression (the most recent) will get
    # listed.
    # Returns a list of errors, from the oldest to the most recent.
    #
    # Could be useful when considering a process where multiple replay
    # attempts failed.
    #
    def ErrorJournal.reduce_error_list (errors)

      errors.inject({}) { |h, e|
        h[e.fei] = e; h
          # last errors do override previous errors for the same fei
      }.values.sort { |error_a, error_b|
        error_a.date <=> error_b.date
      }
    end
  end

  #
  # Stores all the errors in a hash... For testing purposes only, like
  # the InMemoryExpressionStorage.
  #
  class InMemoryErrorJournal < ErrorJournal

    def initialize (service_name, application_context)

      super

      @per_processes = {}
    end

    # Returns a list (older first) of the errors for a process
    # instance identified by its fei or wfid.
    #
    # Will return an empty list if there a no errors for the process
    # instances.
    #
    def get_error_log (wfid)

      wfid = extract_wfid(wfid, true)
      @per_processes[wfid] || []
    end

    # Removes the error log for a process instance.
    #
    def remove_error_log (wfid)

      wfid = extract_wfid(wfid, true)
      @per_processes.delete(wfid)
    end

    # Removes a list of errors from the error journal.
    #
    # The 'errors' parameter may be a single error (instead of an array).
    #
    def remove_errors (wfid, errors)

      errors = Array(errors)

      log = get_error_log(wfid)

      errors.each do |e|
        log.delete(e)
      end
    end

    # Reads all the error logs currently stored.
    # Returns a hash wfid --> error list.
    #
    def get_error_logs

      @per_processes
    end

    protected

    def record_error (error)

      (@per_processes[error.wfid] ||= []) << error
        # not that unreadable after all...
    end
  end
end

