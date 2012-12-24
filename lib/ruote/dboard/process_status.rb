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

require 'ruote/util/tree'
require 'ruote/dboard/process_error'


module Ruote

  #
  # A 'view' on the status of a process instance.
  #
  # Returned by the #process and the #processes methods of Ruote::Dashboard.
  #
  class ProcessStatus

    # The expressions that compose the process instance.
    #
    attr_reader :expressions

    # Returns the expression at the root of the process instance.
    #
    attr_reader :root_expression

    # An array of the workitems currently in the storage participant for this
    # process instance.
    #
    # Do not confuse with #workitems
    #
    attr_reader :stored_workitems

    # An array of errors currently plaguing the process instance. Hopefully,
    # this array is empty.
    #
    attr_reader :errors

    # An array of schedules (open structs yielding information about the
    # schedules of this process)
    #
    attr_reader :schedules

    # TODO
    #
    attr_reader :trackers

    # Called by Ruote::Dashboard#processes or Ruote::Dashboard#process.
    #
    def initialize(context, expressions, sworkitems, errors, schedules, trackers)

      #
      # preparing data

      @expressions = expressions.collect { |e|
        Ruote::Exp::FlowExpression.from_h(context, e)
      }.sort_by { |e|
        e.fei.expid
      }

      @stored_workitems = sworkitems.map { |h| Ruote::Workitem.new(h) }

      @errors = errors.sort! { |a, b| a.fei.expid <=> b.fei.expid }
      @schedules = schedules.sort! { |a, b| a['owner'].sid <=> b['owner'].sid }

      @root_expression = root_expressions.first

      #
      # linking errors and expressions for easy navigation

      @errors.each do |err|
        err.flow_expression = @expressions.find { |fexp| fexp.fei == err.fei }
        err.flow_expression.error = err if err.flow_expression
      end

      @trackers = trackers
    end

    # Returns a list of all the expressions that have no parent expression.
    # The list is sorted with the deeper (closer to the original root) first.
    #
    def root_expressions

      roots = @expressions.select { |e| e.h.parent_id == nil }

      roots = roots.each_with_object({}) { |e, h|
        h["#{e.h.fei['expid']}__#{e.h.fei['subid']}"] = e
      }

      roots.keys.sort.collect { |k| roots[k] }
    end

    # Given an expression id, returns the root (top ancestor) for its
    # expression.
    #
    def root_expression_for(fei)

      sfei = Ruote.sid(fei)

      exp = @expressions.find { |fe| sfei == Ruote.sid(fe.fei) }

      return nil unless exp
      return exp if exp.parent_id.nil?

      root_expression_for(exp.parent_id)
    end

    # Returns the process variables set for this process instance.
    #
    # Returns nil if there is no defined root expression.
    #
    def variables

      @root_expression && @root_expression.variables
    end

    # Returns a hash fei => variable_hash containing all the variable bindings
    # (expression by expression) of the process instance.
    #
    def all_variables

      return nil if @expressions.empty?

      @expressions.each_with_object({}) { |exp, h|
        h[exp.fei] = exp.variables if exp.variables
      }
    end

    # Returns a hash tagname => fei of tags set at the root of the process
    # instance.
    #
    # Returns nil if there is no defined root expression.
    #
    def tags

      variables ? Hash[variables.select { |k, v| Ruote.is_a_fei?(v) }] : nil
    end

    # Returns a hash tagname => array of feis of all the tags set in the process
    # instance.
    #
    def all_tags

      all_variables.remap do |(fei, vars), h|
        vars.each { |k, v| (h[k] ||= []) << v if Ruote.is_a_fei?(v) }
      end
    end

    # Returns the list of "past tags", tags that have been entered and left.
    #
    # The list elements look like:
    #
    #   [ full_tagname, fei_as_string, nil_or_left_status, variables ]
    #
    # For example:
    #
    #   [ 'a', '0_1_0!8f233fb935c!20120106-jagitepi', nil, {} ]
    #
    # or
    #
    #   [ 'stage0/stage1', '0_1_0!8fb935c666d!20120106-jagitepi', 'cancelling', nil ]
    #
    # The second to last entry is nil when the tag (its expression) replied
    # normally, if it was cancelled or something else, the entry contains
    # a string describing the reason ('cancelling' here).
    # The last entry is the variables as they were at the tag point when
    # the execution left the tag.
    #
    def past_tags

      (@root_expression ?
        @root_expression.variables['__past_tags__'] : nil
      ) || []
    end

    # Returns the unique identifier for this process instance.
    #
    def wfid

      l = [ @expressions, @errors, @stored_workitems ].find { |l| l.any? }

      l ? l.first.fei.wfid : nil
    end

    # For a process
    #
    #   Ruote.process_definition :name => 'review', :revision => '0.1' do
    #     author
    #     reviewer
    #   end
    #
    # will yield 'review'.
    #
    def definition_name

      @root_expression && (
        @root_expression.attribute('name') ||
        @root_expression.attribute_text)
    end

    # For a process
    #
    #   Ruote.process_definition :name => 'review', :revision => '0.1' do
    #     author
    #     reviewer
    #   end
    #
    # will yield '0.1'.
    #
    def definition_revision

      @root_expression && (
        @root_expression.attribute('revision') ||
        @root_expression.attribute('rev'))
    end

    # Returns the 'position' of the process.
    #
    #   pdef = Ruote.process_definition do
    #     alpha :task => 'clean car'
    #   end
    #   wfid = engine.launch(pdef)
    #
    #   sleep 0.500
    #
    #   engine.process(wfid) # => [["0_0", "alpha", {"task"=>"clean car"}]]
    #
    # A process with concurrent branches will yield multiple 'positions'.
    #
    # It uses #workitems underneath.
    #
    # If you want to list all the expressions where the "flow currently is"
    # regardless they are participant expressions or errors, look at the
    # #leaves method.
    #
    def position

      workitems.collect { |wi|

        r = [ wi.fei.sid, wi.participant_name ]

        params = (wi.fields['params'] || {}).dup
        params.delete('ref')

        if err = errors.find { |e| e.fei == wi.fei }
          params['error'] = err.message
        end

        r << params
        r
      }
    end

    # Returns the expressions where the flow is currently, ak the leaves
    # of the execution tree.
    #
    # Whereas #position only looks at participant expressions (and errors),
    # #leaves looks at any expressions that is a leave (which has no
    # child at this point).
    #
    # Returns an array of FlowExpression instances. (Note that they may
    # have their attribute #error set).
    #
    def leaves

      expressions.inject([]) { |a, exp|
        a.select { |e| ! exp.ancestor?(e.fei) } + [ exp ]
      }
    end

    # Returns the workitem as was applied at the root expression.
    #
    # Returns nil if no root expression could be found.
    #
    def root_workitem

      return nil unless root_expression

      Ruote::Workitem.new(root_expression.h.applied_workitem)
    end

    # Returns a list of the workitems currently 'out' to participants
    #
    # For example, with an instance of
    #
    #   Ruote.process_definition do
    #     concurrence do
    #       alpha :task => 'clean car'
    #       bravo :task => 'sell car'
    #     end
    #   end
    #
    # calling engine.process(wfid).workitems will yield two workitems
    # (alpha and bravo).
    #
    # Warning : do not confuse the workitems here with the workitems held
    # in a storage participant or equivalent.
    #
    def workitems

      @expressions.select { |fexp|
        #fexp.is_a?(Ruote::Exp::ParticipantExpression)
        fexp.h.name == 'participant'
      }.collect { |fexp|
        Ruote::Workitem.new(fexp.h.applied_workitem)
      }
    end

    # Returns a parseable UTC datetime string which indicates when the process
    # was last active.
    #
    def last_active

      @expressions.collect { |fexp| fexp.h.put_at }.max
    end

    # Returns the process definition tree as it was when this process instance
    # was launched.
    #
    def original_tree

      @root_expression && @root_expression.original_tree
    end

    # Returns a Time instance indicating when the process instance was launched.
    #
    def launched_time

      @root_expression && @root_expression.created_time
    end

    def to_s

      '(' + [
        "process_status wfid '#{wfid}'",
        "expressions #{@expressions.size}",
        "stored_workitems #{@stored_workitems.size}",
        "errors #{@errors.size}",
        "schedules #{@schedules.size}",
        "trackers #{@trackers.size}"
      ].join(', ') + ')'
    end

    def hinspect(indent, h)

      if h
        h.collect { |k, v|
          s << "#{' ' * indent}#{k.inspect}: #{v.inspect}"
        }.join("\n")
      else
        "#{' ' * indent}(nil)"
      end
    end

    def inspect

      vars = variables rescue nil
      avars = (all_variables || {}).remap { |(k, v), h| h[Ruote.sid(k)] = v }


      s = [ "== #{self.class} ==" ]
      s << ''
      s << "  wfid:           #{wfid}"
      s << "  name:           #{definition_name}"
      s << "  revision:       #{definition_revision}"
      s << "  last_active:    #{last_active}"
      s << "  launched_time:  #{launched_time}"
      s << ''

      s << "  expressions: #{@expressions.size}"
      s << ''
      @expressions.each do |e|

        eflags = %w[
          flanking forgotten attached
        ].each_with_object([]) { |f, a| a << f if e.h[f] }

        s << "     #{e.fei.to_storage_id}"
        s << "       | #{e.name}"
        s << "       | _rev: #{e.h._rev.inspect}"
        s << "       | * #{e.state} *" if e.state
        s << "       | #{e.attributes.inspect}"
        e.children.each do |ce|
          s << "       | . child-> #{Ruote.sid(ce)}"
        end if e.children.any?
        s << "       | timers: #{e.h.timers.collect { |t| t[1] }}" if e.h.timers
        s << "       | tagname: #{e.h.tagname}" if e.h.tagname
        s << "       | (#{eflags.join(', ')})" if eflags.any?
        s << "       `-parent--> #{e.h.parent_id ? e.parent_id.to_storage_id : 'nil'}"
      end

      s << ''
      s << "  schedules: #{@schedules.size}"
      if @schedules.size > 0
        @schedules.each do |sched|
          s << "    * #{sched['original']}"
          s << "      #{sched['flavour']} #{sched['at']}"
          s << "      #{sched['action']}"
          s << "      #{Ruote.sid(sched['target']) rescue '** no target **'}"
        end
        s << ''
      end

      s << "  stored workitems: #{@stored_workitems.size}"

      s << ''
      s << "  initial workitem fields:"
      if @root_expression
        s << hinspect(4, @root_expression.h.applied_workitem['fields'])
      else
        s << "    (no root expression identified)"
      end

      s << ''
      s << "  variables:"; s << hinspect(4, vars)
      s << ''
      s << "  all_variables:"; s << hinspect(4, avars)
      s << ''
      s << "  errors: #{@errors.size}"
      @errors.each do |e|
        s << "    ***"
        s << "      #{e.fei.to_storage_id} :" if e.fei
        s << "    action: #{e.action}"
        s << "    message: #{e.message}"
        s << "    trace:"
        e.trace.split("\n").each do |line|
          s << "      #{line}"
        end
        s << "    details:"
        (e.details || '').split("\n").each do |line|
          s << "      #{line}"
        end
        if e.respond_to?(:deviations)
          s << "    deviations:"
          (e.deviations || []).each do |line|
            s << "      #{line.inspect}"
          end
        end
        s << "    fields:"; s << hinspect(6, e.fields)
      end

      # TODO: add trackers

      s.join("\n") + "\n"
    end

    # Returns a 'dot' representation of the process. A graph describing
    # the tree of flow expressions that compose the process.
    #
    def to_dot(opts={})

      s = [ "digraph \"process wfid #{wfid}\" {" ]
      @expressions.each { |e| s.push(*e.send(:to_dot, opts)) }
      @errors.each { |e| s.push(*e.send(:to_dot, opts)) }
      s << '}'

      s.join("\n")
    end

    # Outputs the process status as a hash (easily JSONifiable).
    #
    def to_h

      %w[
        expressions errors stored_workitems schedules trackers
      ].each_with_object({}) do |a, h|

        k = a == 'stored_workitems' ? 'workitems' : a

        v = self.send(a)
        v = v.collect { |e| e.respond_to?(:h) ? e.h : e }

        h[k] = v
      end
    end

    # Returns the current version of the process definition tree. If no
    # manipulation (gardening) was performed on the tree, this method yields
    # the same result as the #original_tree method.
    #
    # Returns nil if there are no expressions (happens in the case of an
    # orphan workitem)
    #
    def current_tree(fexp=root_expression)

      return nil unless fexp

      t = Ruote.fulldup(fexp.tree)

      fexp.children.each do |cfei|

        cexp = fexp(cfei)
        next unless cexp

        ct = current_tree(cexp)

        #trigger = ct[1]['_triggered']
        #if trigger && trigger != 'on_re_apply'
        #    #
        #  # ignore any on_cancel / on_error / ...
        #  #
        #  #ct = t[2][cexp.child_id]
        #  # loses any change in the re_applied tree
        #    #
        #  # just flag the original tree as _triggered
        #  # loses any change in the re_applied tree
        #  #
        #  #ct = t[2][cexp.child_id]
        #  #ct[1]['_triggered'] = trigger
        #    #
        #  # extracts the new tree, discards the layers around it
        #  #
        #  ot = t[2][cexp.child_id]
        #  ct = ct[2][0][2][0]
        #  ct[1]['_triggered'] = [ trigger, ot[1][trigger] ].join('/')
        #end
          # return the real current tree, do not tweak with it!

        t[2][cexp.child_id] = ct
      end

      t
    end

    # Used by Ruote::Dashboard#process and #processes
    #
    def self.fetch(context, wfids, opts)

      swfids = wfids.collect { |wfid| /!#{wfid}-\d+$/ }

      batch = { 'id' => "#{Thread.current.object_id}-#{Time.now.to_f}" }
        #
        # some storages may optimize when they can distinguish
        # which get_many fit in the same batch...

      exps = context.storage.get_many(
        'expressions', wfids, :batch => batch).compact
      swis = context.storage.get_many(
        'workitems', wfids, :batch => batch).compact
      errs = context.storage.get_many(
        'errors', wfids, :batch => batch).compact
      schs = context.storage.get_many(
        'schedules', swfids, :batch => batch).compact
          #
          # some slow storages need the compaction... couch...

      errs = errs.collect { |err| ProcessError.new(err) }
      schs = schs.collect { |sch| Ruote.schedule_to_h(sch) }

      by_wfid = {}
      as = lambda { [ [], [], [], [], [] ] }

      exps.each { |exp| (by_wfid[exp['fei']['wfid']]  ||= as.call)[0] << exp }
      swis.each { |swi| (by_wfid[swi['fei']['wfid']]  ||= as.call)[1] << swi }
      errs.each { |err| (by_wfid[err.wfid]            ||= as.call)[2] << err }
      schs.each { |sch| (by_wfid[sch['wfid']]         ||= as.call)[3] << sch }
      # TODO: trackers

      wfids = by_wfid.keys.sort
      wfids = wfids.reverse if opts[:descending]
        # re-adjust list of wfids, only take what was found

      wfids.collect { |wfid|
        info = by_wfid[wfid]
        info ? self.new(context, *info) : nil
      }.compact
    end

    # Given a fei, returns the flow expression with that fei (only looks
    # in the expressions stored here, in this ProcessStatus instance, doesn't
    # query the storage).
    #
    def fexp(fei)

      fei = Ruote.extract_fei(fei)

      @expressions.find { |e| e.fei == fei }
    end
  end
end

