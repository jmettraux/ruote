#--
# Copyright (c) 2005-2011, John Mettraux, jmettraux@gmail.com
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
require 'ruote/dashboard/process_error'


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

    # Called by Ruote::Dashboard#processes or Ruote::Dashboard#process.
    #
    def initialize(context, expressions, stored_workitems, errors, schedules)

      #
      # preparing data

      @expressions = expressions.collect { |e|
        Ruote::Exp::FlowExpression.from_h(context, e) }
      @expressions.sort! { |a, b| a.fei.expid <=> b.fei.expid }

      @stored_workitems = stored_workitems.collect { |h|
        Ruote::Workitem.new(h)
      }

      @errors = errors.sort! { |a, b| a.fei.expid <=> b.fei.expid }
      @schedules = schedules.sort! { |a, b| a['owner'].sid <=> b['owner'].sid }

      @root_expression = root_expressions.first

      #
      # linking errors and expressions for easy navigation

      @errors.each do |err|
        err.flow_expression = @expressions.find { |fexp| fexp.fei == err.fei }
        err.flow_expression.error = err if err.flow_expression
      end
    end

    # Returns a list of all the expressions that have no parent expression.
    # The list is sorted with the deeper (closer to the original root) first.
    #
    def root_expressions

      roots = @expressions.select { |e| e.h.parent_id == nil }

      roots = roots.inject({}) { |h, e|
        h["#{e.h.fei['expid']}__#{e.h.fei['subid']}"] = e; h
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
    def variables

      @root_expression && @root_expression.variables
    end

    # Returns a hash fei => variable_hash containing all the variable bindings
    # (expression by expression) of the process instance.
    #
    def all_variables

      @expressions.inject({}) do |h, exp|
        h[exp.fei] = exp.variables if exp.variables
        h
      end
    end

    # Returns a hash tagname => fei of tags set at the root of the process
    # instance.
    #
    def tags

      Hash[variables.select { |k, v| FlowExpressionId.is_a_fei?(v) }]
    end

    # Returns a hash tagname => array of feis of all the tags set in the process
    # instance.
    #
    def all_tags

      all_variables.inject({}) do |h, (fei, vars)|
        vars.each { |k, v| (h[k] ||= []) << v if FlowExpressionId.is_a_fei?(v) }
        h
      end
    end

    # Returns the unique identifier for this process instance.
    #
    def wfid

      @expressions.any? ? @expressions.first.fei.wfid : @errors.first.fei.wfid
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
    def root_workitem

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
        fexp.is_a?(Ruote::Exp::ParticipantExpression)
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

      "(" + [
        "process_status wfid '#{wfid}'",
        "expressions #{@expressions.size}",
        "stored_workitems #{@stored_workitems.size}",
        "errors #{@errors.size}",
        "schedules #{@schedules.size}"
      ].join(', ') + ")"
    end

    def hinspect(indent, h)

      h.collect { |k, v|
        s << "#{' ' * indent}#{k.inspect}: #{v.inspect}"
      }.join("\n")
    end

    def inspect

      vars = variables rescue nil
      avars = all_variables.inject({}) { |h, (k, v)| h[Ruote.sid(k)] = v; h }

      s = [ "== #{self.class} ==" ]
      s << ''
      s << "  expressions: #{@expressions.size}"
      s << ''
      @expressions.each do |e|
        s << "     #{e.fei.to_storage_id}"
        s << "       | #{e.name}"
        s << "       | * #{e.state} *" if e.state
        s << "       | #{e.attributes.inspect}"
        s << "       `-parent--> #{e.h.parent_id ? e.parent_id.to_storage_id : 'nil'}"
      end
      s << ''
      s << "  schedules: #{@schedules.size}"
      s << "  stored workitems: #{@stored_workitems.size}"
      s << ''
      s << "  variables:"; s << hinspect(4, vars)
      s << ''
      s << "  all_variables:"; s << hinspect(4, avars)
      s << ''
      s << "  errors: #{@errors.size}"
      @errors.each do |e|
        s << "    ***"
        s << "     #{e.fei.to_storage_id} :" if e.fei
        s << "    action: #{e.action}"
        s << "    message: #{e.message}"
        s << "    trace:"
        e.trace.split("\n").each do |line|
          s << "       #{line}"
        end
        s << "    fields:"; s << hinspect(6, e.fields)
      end

      s.join("\n") + "\n"
    end

    # Returns a 'dot' representation of the process. A graph describing
    # the tree of flow expressions that compose the process.
    #
    def to_dot(opts={})

      s = [ "digraph \"process wfid #{wfid}\" {" ]
      @expressions.each { |e| s.push(*e.send(:to_dot, opts)) }
      @errors.each { |e| s.push(*e.send(:to_dot, opts)) }
      s << "}"

      s.join("\n")
    end

    #--
    #def to_h
    #  h = {}
    #  %w[
    #    wfid
    #    definition_name definition_revision
    #    original_tree current_tree
    #    variables tags
    #  ].each { |m| h[m] = self.send(m) }
    #  h['launched_time'] = launched_time
    #  h['last_active'] = last_active
    #  # all_variables and all_tags ?
    #  h['root_expression'] = nil
    #  h['expressions'] = @expressions.collect { |e| e.fei.to_h }
    #  h['errors'] = @errors.collect { |e| e.to_h }
    #  h
    #end
    #++

    # Returns the current version of the process definition tree. If no
    # manipulation (gardening) was performed on the tree, this method yields
    # the same result as the #original_tree method.
    #
    def current_tree

      h = Ruote.decompose_tree(original_tree)

      @expressions.sort { |e0, e1|

        e0.fei.expid <=> e1.fei.expid

      }.each { |e|

        trigger = e.tree[1]['_triggered']

        tree = if trigger && trigger != 'on_re_apply'
          t = original_tree_from_parent(e).dup
          t[1]['_triggered'] = trigger
          t
        else
          e.tree
        end

        h.merge!(Ruote.decompose_tree(tree, e.fei.expid))
      }

      Ruote.recompose_tree(h)
    end

    # Used by Ruote::Dashboard#process and #processes
    #
    def self.fetch(context, wfids, opts)

      swfids = wfids.collect { |wfid| /!#{wfid}-\d+$/ }

      batch = "#{Thread.current.object_id}-#{Time.now.to_f}"
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

      exps.each do |exp|
        (by_wfid[exp['fei']['wfid']] ||= [ [], [], [], [] ])[0] << exp
      end
      swis.each do |swi|
        (by_wfid[swi['fei']['wfid']] ||= [ [], [], [], [] ])[1] << swi
      end
      errs.each do |err|
        (by_wfid[err.wfid] ||= [ [], [], [], [] ])[2] << err
      end
      schs.each do |sch|
        (by_wfid[sch['wfid']] ||= [ [], [], [], [] ])[3] << sch
      end

      wfids = by_wfid.keys.sort
      wfids = wfids.reverse if opts[:descending]
        # re-adjust list of wfids, only take what was found

      wfids.inject([]) { |a, wfid|
        if info = by_wfid[wfid]
          a << ProcessStatus.new(context, *info)
        end
        a
      }
    end

    protected

    def original_tree_from_parent(e)

      parent = @expressions.find { |exp| exp.fei == e.parent_id }

      parent ? parent.tree[2][e.fei.child_id] : e.tree
    end
  end
end

