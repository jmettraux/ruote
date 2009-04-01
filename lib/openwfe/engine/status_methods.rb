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
    # A list of all the applied workitems found in the process
    # (participant expressions, for example, do keep a copy of the workitem
    # they dispatched to the actual participant.
    #
    attr_reader :applied_workitems

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
      @applied_workitems = []
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
    # Returns a list of the expression ids of the workitem currently active
    # for this process
    #
    def workitem_expids

      @expressions.collect { |exp| exp.fei.expid }
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

      #@all_expressions.representation
      @all_expressions.tree
    end

    #
    # Returns the tree (representation of the process definition) as it
    # was when the process instance was launched (in-flight modifications
    # are NOT taken into account).
    #
    def initial_tree

      #@all_expressions.find_root_expression.raw_representation
      @all_expressions.initial_tree
    end

    #
    # this method is used by Engine.get_process_status() when
    # it prepares its results.
    #
    def << (item)

      if item.is_a?(FlowExpression)

        fei = item.fei

        @wfid ||= fei.parent_wfid

        @variables = item.variables if (
          item.is_a?(Environment) and
          fei.sub_instance_id == '' and
          fei.expid == '0')

        @launch_time ||= item.apply_time \
          if item.fei.expid == '0' and item.fei.is_in_parent_process?

        @all_expressions << item

        wi = nil
        wi = item.applied_workitem if item.respond_to?(:applied_workitem)
        @applied_workitems << wi if wi

      else

        @errors[item.fei] = item
      end
    end

    #--
    # A lighter version
    #
    #def to_h
    #end
    #
    #  moved to lib/openwfe/representations.rb
    #++

    protected

    #
    # Prepares the @expressions instance variable. This method
    # is only called by the process_status method of the Engine.
    #
    def pack_expressions

      @expressions = []

      @all_expressions.sort_by { |fe|
        "#{fe.fei.wfid} #{fe.fei.expid}"
      }.each do |fe|

        next unless fe.apply_time
          # no Environment instances allowed

        @expressions.delete_if { |e| e.fei == fe.parent_id }

        @expressions << fe
      end
    end
  end

  #
  # Simply adding a timestamp
  #
  module StatusesMixin

    attr_accessor :timestamp
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

      all = (options == {})

      return @all_status_cache if all and @all_status_cache

      init_status_cache unless @status_cache

      options = { :wfid_prefix => options } if options.is_a?(String)

      expressions = get_expression_storage.find_expressions(options)

      result = expressions.inject({}) do |r, fe|
        (r[fe.fei.parent_wfid] ||= ProcessStatus.new) << fe; r
      end

      result.values.each do |ps|

        ps.paused = (get_expool.paused_instances[ps.wfid] != nil)

        get_error_journal.get_error_log(ps.wfid).each { |er| ps << er }

        ps.send(:pack_expressions) # letting it protected

        ps.scheduled_jobs = get_scheduler.find_jobs(ps.wfid)
      end

      result.delete('0')
      @status_cache.delete('0')

      #
      # done

      result.extend(StatusesMixin)
      result.timestamp = Time.now

      @all_status_cache = result if all

      result
    end

    # list_process_status() will be deprecated at release 1.0.0
    #alias :list_process_status :process_statuses

    #
    # Like process_statuses, but returns an Array (of ProcessStatus instances)
    # instead of a Hash.
    #
    def processes (options={})

      process_statuses(options).values
    end

    #
    # Returns the process status of one given process instance.
    #
    def process_status (wfid)

      init_status_cache unless @status_cache

      (r = @status_cache[wfid]) and return r

      wfid = extract_wfid(wfid, true)

      #process_statuses(:wfid_prefix => wfid).values.first
      process_statuses(:wfid => wfid).values.first
    end

    #
    # Returns true if the process is in pause.
    #
    def is_paused? (wfid)

      (get_expression_pool.paused_instances[wfid] != nil)
    end
  end

end

