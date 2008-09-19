#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
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

module OpenWFE

  #
  # ProcessStatus represents information about the status of a workflow
  # process instance.
  #
  # The status is mainly a list of expressions and a hash of errors.
  #
  # Instances of this class are obtained via Engine.process_status().
  #
  class ProcessStatus

    #
    # the String workflow instance id of the Process.
    #
    attr_reader :wfid

    #
    # The list of the expressions currently active in the process instance.
    #
    # For instance, if your process definition is currently in a
    # concurrence, more than one expressions may be listed here.
    #
    attr_reader :expressions

    #
    # The list of all the expressions in the process (active or not).
    #
    attr_reader :all_expressions

    #
    # A hash whose values are ProcessError instances, the keys
    # are FlowExpressionId instances (fei) (identifying the expressions
    # that are concerned with the error)
    #
    attr_reader :errors

    #
    # The time at which the process got launched.
    #
    attr_reader :launch_time

    #
    # The variables hash as set in the process environment (the process
    # scope).
    #
    attr_reader :variables

    #
    # The jobs registered for that process instance in the rufus
    # scheduler used by the engine.
    #
    attr_accessor :scheduled_jobs

    #
    # Is the process currently in pause ?
    #
    attr_accessor :paused

    #
    # When was this ProcessStatus instance generated ?
    #
    attr_accessor :timestamp

    #
    # Builds an empty ProcessStatus instance.
    #
    def initialize

      @wfid = nil
      @expressions = nil
      @all_expressions = []
      @errors = {}
      @launch_time = nil
      @variables = nil
      @scheduled_jobs = nil
      @paused = false
      @timestamp = Time.now

      @all_expressions.extend(RepresentationMixin)
    end

    #
    # Returns the workflow definition name for this process.
    #
    def wfname

      @expressions.first.fei.wfname
    end

    alias :workflow_definition_name :wfname

    #
    # Returns the workflow definition revision for this process.
    #
    def wfrevision

      @expressions.first.fei.wfrevision
    end

    alias :workflow_definition_revision :wfrevision

    #
    # Returns the count of concurrent branches currently active for
    # this process. The typical 'sequential only' process will
    # have a return value of 1 here.
    #
    def branches

      @expressions.size
    end

    #
    # Returns the tags currently set in this process.
    #
    def tags

      return [] unless @variables

      @variables.keys.select do |k|
        @variables[k].is_a?(OpenWFE::RawExpression::Tag)
      end
    end

    #
    # Returns true if the process is in pause.
    #
    def paused?

      #@expressions.first.paused?
      @paused
    end

    #
    # Returns the tree (representation of the process definition) as it
    # currently is (in-flight modifications taken into account).
    #
    def current_tree

      @all_expressions.representation
    end

    #
    # Returns the tree (representation of the process definition) as it
    # was when the process instance was launched (in-flight modifications
    # are NOT taken into account).
    #
    def initial_tree

      @all_expressions.find_root_expression.raw_representation
    end

    #
    # this method is used by Engine.get_process_status() when
    # it prepares its results.
    #
    def << (item)

      if item.is_a?(FlowExpression)

        @wfid ||= item.fei.parent_wfid

        @variables = item.variables \
          if item.is_a?(Environment) and item.fei.expid == "0"

        @launch_time ||= item.apply_time \
          if item.fei.expid == '0' and item.fei.is_in_parent_process?

        @all_expressions << item

      else

        @errors[item.fei] = item
      end
    end

    #
    # A lighter version
    #
    def to_h (options={})
      {
        'href' => OpenWFE::href(options, [ :processes, wfid ]),
        'timestamp' => timestamp.to_s,
        'wfid' => wfid,
        'launch_time' => launch_time,
        'paused' => paused,
        'variables' => variables,
        'tags' => tags
      }
    end

    protected

      #
      # Prepares the @expressions instance variable. This method
      # is only called by the process_status method of the Engine.
      #
      def pack_expressions

        @expressions = []

        @all_expressions.sort_by { |fe| fe.fei.expid }.each do |fe|

          next unless fe.apply_time
            # no Environment or RawExpression instances

          @expressions.delete_if { |e| e.fei == fe.parent_id }

          @expressions << fe
        end
      end
  end

  #
  # just a nice to_s for the ProcessStatuses hash
  #
  module StatusesMixin

    attr_accessor :timestamp

    #
    # Renders a nice, terminal oriented, representation of an
    # Engine.get_process_status() result.
    #
    # You usually directly benefit from this when doing
    #
    #   puts engine.get_process_status.to_s
    #
    def to_s

      # TODO : include launch_time and why is process_id so long ?

      s = ""
      s << "process_id      | name        | rev   | brn | err | paused? \n"
      s << "--------------------+-------------------+---------+-----+-----+---------\n"

      self.keys.sort.each do |wfid|

        status = self[wfid]
        fexp = status.expressions.first
        ffei = fexp.fei

        s << "%-19s" % wfid[0, 19]
        s << " | "
        s << "%-17s" % ffei.workflow_definition_name[0, 17]
        s << " | "
        s << "%-7s" % ffei.workflow_definition_revision[0, 7]
        s << " | "
        s << "%3s" % status.expressions.size.to_s[0, 3]
        s << " | "
        s << "%3s" % status.errors.size.to_s[0, 3]
        s << " | "
        s << "%5s" % status.paused?.to_s
        s << "\n"
      end

      s
    end
  end

  #
  # This mixin is only included by the Engine class. It contains all
  # the methods about ProcessStatus.
  #
  # Note : it caches process status to avoid too big a load on the
  # expression storage, the weeping mecha stays here.
  #
  module StatusMethods

    def init_status_cache

      @status_cache = LruHash.new(30)
      @all_status_cache = nil

      get_expression_pool.add_observer(:all) do |event, *args|
        fei = args.find { |a| a.is_a?(FlowExpressionId) }
        @status_cache.delete(fei.wfid) if fei
        @all_status_cache = nil if fei or event == :launch
      end
    end

    #
    # Returns a hash of ProcessStatus instances. The keys of the hash
    # are workflow instance ids.
    #
    # A ProcessStatus is a description of the state of a process instance.
    # It enumerates the expressions where the process is currently
    # located (waiting certainly) and the errors the process currently
    # has (hopefully none).
    #
    # the :wfid_prefix option is useful when you want to list all the process
    # for a year (:wfid_prefix => '2007'), a month (:wfid_prefix => '200705') or
    # a day (:wfid_prefix => '20070529').
    #
    def process_statuses (options={})

      return @all_status_cache if options == {} and @all_status_cache

      init_status_cache unless @status_cache

      options = { :wfid_prefix => options } if options.is_a?(String)

      expressions = get_expression_storage.find_expressions(options)

      result = expressions.inject({}) do |r, fe|

        #next unless (fe.apply_time or fe.is_a?(Environment))
        #next if fe.fei.wfid == '0' # skip the engine env

        (r[fe.fei.parent_wfid] ||= ProcessStatus.new) << fe
        r
      end

      result.values.each do |ps|

        ps.paused = (get_expool.paused_instances[ps.wfid] != nil)

        get_error_journal.get_error_log(ps.wfid).each { |er| ps << er }

        ps.send :pack_expressions # letting it protected

        ps.scheduled_jobs = get_scheduler.find_jobs(ps.wfid)

        if ps.expressions.size == 0
          # drop result if there are no expressions
          result.delete(ps.wfid)
          @status_cache.delete(ps.wfid)
        else
          @status_cache[ps.wfid] = ps
        end
      end

      #
      # done

      result.extend(StatusesMixin)
      result.timestamp = Time.now

      @all_status_cache = result
        # cache and return
    end

    #
    # list_process_status() will be deprecated at release 1.0.0
    #
    alias :list_process_status :process_statuses

    #
    # Returns the process status of one given process instance.
    #
    def process_status (wfid)

      init_status_cache unless @status_cache

      (r = @status_cache[wfid]) and return r

      wfid = extract_wfid(wfid, true)

      process_statuses(:wfid_prefix => wfid).values.first
    end

    #
    # Returns true if the process is in pause.
    #
    def is_paused? (wfid)

      (get_expression_pool.paused_instances[wfid] != nil)
    end
  end

end

