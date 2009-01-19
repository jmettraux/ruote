#
#--
# Copyright (c) 2007-2009, John Mettraux, OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

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

    #
    # When did the error occur.
    #
    attr_reader :date

    #
    # The FlowExpressionId instance uniquely pointing at the expression
    # which 'failed'.
    #
    attr_reader :fei

    #
    # Generally something like :apply or :reply
    #
    attr_reader :message

    #
    # The workitem accompanying the message (apply(workitem) /
    # reply (workitem)).
    #
    attr_reader :workitem

    #
    # The String stack trace of the error.
    #
    attr_reader :stacktrace

    #
    # The error class (String) of the top level error
    #
    attr_reader :error_class

    def initialize (*args)

      @date = Time.new
      @fei, @message, @workitem, @error_class, @stacktrace = args
    end

    #
    # Returns the parent workflow instance id (process id) of this
    # ProcessError instance.
    #
    def wfid
      @fei.parent_wfid
    end

    alias :parent_wfid :wfid

    #
    # Produces a human readable version of the information in the
    # ProcessError instance.
    #
    def to_s
      s = ""
      s << "-- #{self.class.name} --\n"
      s << "   date :    #{@date}\n"
      s << "   fei :     #{@fei}\n"
      s << "   message :   #{@message}\n"
      s << "   workitem :  ...\n"
      s << "   error_class : #{@error_class}\n"
      s << "   stacktrace :  #{@stacktrace[0, 80]}\n"
      s
    end

    #
    # Returns a hash
    #
    def hash
      to_s.hash
        #
        # a bit costly but as it's only used by resume_process()...
    end

    #
    # Returns true if the other instance is a ProcessError and is the
    # same error as this one.
    #
    def == (other)
      return false unless other.is_a?(ProcessError)
      return to_s == other.to_s
        #
        # a bit costly but as it's only used by resume_process()...
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

      get_expression_pool.add_observer :error do |event, *args|
        #
        # logs each error occurring in the expression pool

        begin

          record_error(ProcessError.new(*args))

        rescue Exception => e
          lwarn { "(failed to record error : #{e})" }
          lwarn { "*** process error : \n" + args.join("\n") }
        end
      end

      get_expression_pool.add_observer :terminate do |event, *args|
        #
        # removes error log when a process terminates

        fei = args[0].fei

        remove_error_log fei.wfid \
          if fei.is_in_parent_process?
      end
    end

    #
    # Returns true if the given wfid (or fei) (process instance id)
    # has had errors.
    #
    def has_errors? (wfid)

      get_error_log(wfid).size > 0
    end

    #
    # Takes care of removing an error from the error journal and
    # they replays its process at that point.
    #
    def replay_at_error (error)

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

    #
    # A utility method : given a list of errors, will make sure that for
    # each flow expression only one expression (the most recent) will get
    # listed.
    # Returns a list of errors, from the oldest to the most recent.
    #
    # Could be useful when considering a process where multiple replay
    # attempts failed.
    #
    def ErrorJournal.reduce_error_list (errors)

      h = {}

      errors.each do |e|
        h[e.fei] = e
          #
          # last errors do override previous errors for the
          # same fei
      end

      h.values.sort do |error_a, error_b|
        error_a.date <=> error_b.date
      end
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

    #
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

    #
    # Removes the error log for a process instance.
    #
    def remove_error_log (wfid)

      wfid = extract_wfid(wfid, true)
      @per_processes.delete(wfid)
    end

    #
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

    #
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
