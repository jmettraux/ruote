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

require 'ruote/util/time'
require 'ruote/util/ometa'
require 'ruote/util/hashdot'


module Ruote::Exp

  #
  # Ruote is a process definition interpreter. It doesn't directly "read"
  # process definitions, it relies on a parser/generator to produce "abstract
  # syntax trees" that look like
  #
  #   [ expression_name, { ... attributes ... }, [ children_expressions ] ]
  #
  # The nodes (and leaves) in the trees are expressions. This is the base
  # class for all expressions.
  #
  # The most visible expressions are "define", "sequence" and "participant".
  # Think :
  #
  #   pdef = Ruote.process_definition do
  #     sequence do
  #       participant :ref => 'customer'
  #       participant :ref => 'accounting'
  #       participant :ref => 'logistics'
  #     end
  #   end
  #
  # Each node is an expression...
  #
  class FlowExpression

    include Ruote::WithH
    include Ruote::WithMeta

    require 'ruote/exp/ro_persist'
    require 'ruote/exp/ro_attributes'
    require 'ruote/exp/ro_variables'
    require 'ruote/exp/ro_filters'
    require 'ruote/exp/ro_vf'

    COMMON_ATT_KEYS = %w[
      if unless forget timeout timers on_error on_cancel on_timeout ]

    attr_reader :h

    h_reader :variables
    h_reader :created_time
    h_reader :original_tree
    h_reader :updated_tree

    h_reader :children
    h_reader :state

    h_reader :on_error
    h_reader :on_cancel
    h_reader :on_timeout

    attr_reader :context

    # Mostly used when the expression is returned via Ruote::Engine#ps(wfid) or
    # Ruote::Engine#processes(). If an error occurred for this flow expression,
    # #ps will set this error field so that it yields the ProcessError.
    #
    # So, for short, usually, this attribute yields nil.
    #
    attr_accessor :error

    def initialize(context, h)

      @context = context

      @msg = nil
        # contains generally the msg the expression got instantiated for

      self.h = h

      h._id ||= Ruote.to_storage_id(h.fei)
      h['type'] ||= 'expressions'
      h.name ||= self.class.expression_names.first
      h.children ||= []
      h.applied_workitem['fei'] = h.fei
      h.created_time ||= Ruote.now_to_utc_s

      h.on_cancel ||= attribute(:on_cancel)
      h.on_error ||= attribute(:on_error)
      h.on_timeout ||= attribute(:on_timeout)
    end

    def h=(hash)

      @h = hash
      class << @h; include Ruote::HashDot; end
    end

    # Returns the Ruote::FlowExpressionId for this expression.
    #
    def fei

      Ruote::FlowExpressionId.new(h.fei)
    end

    # Returns the Ruote::FlowExpressionIf of the parent expression, or nil
    # if there is no parent expression.
    #
    def parent_id

      h.parent_id ?
        Ruote::FlowExpressionId.new(h.parent_id) :
        nil
    end

    # Fetches the parent expression, or returns nil if there is no parent
    # expression.
    #
    def parent

      h.parent_id ?
        Ruote::Exp::FlowExpression.fetch(@context, h.parent_id) :
        nil
    end

    # Returns the root expression of this expression.
    # The result is an instance of Ruote::FlowExpression.
    #
    def root

      exps = @context.storage.find_expressions(h.fei['wfid'])
      current = exps.find { |e| e['fei'] == h.fei }

      while current['parent_id']
        current = exps.find { |e| e['fei'] == current['parent_id'] }
      end

      Ruote::Exp::FlowExpression.from_h(@context, current)
    end

    # Returns the fei of the root expression of this expression.
    # The result is an instance of Ruote::FlowExpressionId.
    #
    def root_id

      root.fei
    end

    # Turns this FlowExpression instance into a Hash (well, just hands back
    # the base hash behind it).
    #
    def to_h

      @h
    end

    # Instantiates expression back from hash.
    #
    def self.from_h(context, h)

      exp_class = context.expmap.expression_class(h['name'])

      exp_class.new(context, h)
    end

    # Fetches an expression from the storage and readies it for service.
    #
    def self.fetch(context, fei)

      return nil if fei.nil?

      fexp = context.storage.get('expressions', Ruote.to_storage_id(fei))

      fexp ? from_h(context, fexp) : nil
    end

    #--
    # META
    #++

    # Keeping track of names and aliases for the expression
    #
    def self.names(*exp_names)

      exp_names = exp_names.collect { |n| n.to_s }
      meta_def(:expression_names) { exp_names }
    end

    #--
    # apply/reply
    #++

    # Called by the worker when it has something to do for a FlowExpression.
    #
    def self.do_action(context, msg)

      fei = msg['fei']
      action = msg['action']

      #p msg unless fei

      if action == 'reply' && fei['engine_id'] != context.engine_id
        #
        # the reply has to go to another engine, let's locate the
        # 'engine participant' and give it the workitem/reply
        #
        # see ft_37 for a test/example

        engine_participant =
          context.plist.lookup(fei['engine_id'], msg['workitem'])

        raise(
          "no EngineParticipant found under name '#{fei['engine_id']}'"
        ) unless engine_participant

        engine_participant.reply(fei, msg['workitem'])
        return
      end

      # normal case

      fexp = nil

      3.times do
        fexp = fetch(context, msg['fei'])
        break if fexp
        sleep 0.028
      end
        # this retry system is only useful with ruote-couch

      fexp.send("do_#{action}", msg) if fexp
    end

    # Called by the worker when it has just created this FlowExpression and
    # wants to apply it.
    #
    def do_apply(msg)

      @msg = Ruote.fulldup(msg)

      if not Condition.apply?(attribute(:if), attribute(:unless))

        return reply_to_parent(h.applied_workitem)
      end

      pi = h.parent_id
      reply_immediately = false

      if attribute(:forget).to_s == 'true'

        h.variables = compile_variables
        h.parent_id = nil
        h.forgotten = true

        #@context.storage.put_msg('reply', 'fei' => pi, 'workitem' => wi) if pi
          # reply to parent immediately (if there is a parent)

        reply_immediately = true

      elsif attribute(:lose).to_s == 'true'

        h.lost = true

      elsif attribute(:flank).to_s == 'true'

        h.flanking = true

        reply_immediately = true
      end

      if reply_immediately and pi

        @context.storage.put_msg(
          'reply',
          'fei' => pi,
          'workitem' => Ruote.fulldup(h.applied_workitem),
          'flanking' => h.flanking)
      end

      filter

      consider_tag
      consider_timers

      apply
    end

    # FlowExpression call this method when they're done and they want their
    # parent expression to take over (it will end up calling the #reply of
    # the parent expression).
    #
    def reply_to_parent(workitem, delete=true)

      filter(workitem)

      if h.tagname

        unset_variable(h.tagname)

        Ruote::Workitem.remove_tag(workitem, h.tagname)

        @context.storage.put_msg(
          'left_tag',
          'tag' => h.tagname,
          'fei' => h.fei,
          'workitem' => workitem)
      end

      if h.timeout_schedule_id #&& h.state != 'timing_out'
        @context.storage.delete_schedule(h.timeout_schedule_id)
      end
        #
        # the flow has a h.timeout_schedule_id, it means it has been started
        # with a pre-timers ruote. We have to remove the schedule anyway.
        #
        # those 3 lines will be removed soon.

      h.timers.each do |schedule_id, action|
        @context.storage.delete_schedule(schedule_id)
      end if h.timers

      if h.state == 'failing' # on_error is implicit (#do_fail got called)

        trigger('on_error', workitem)

      elsif h.state == 'cancelling' and h.on_cancel

        trigger('on_cancel', workitem)

      elsif h.state == 'cancelling' and h.on_re_apply

        trigger('on_re_apply', workitem)

      elsif h.state == 'timing_out' and h.on_timeout

        trigger('on_timeout', workitem)

      elsif h.lost and (h.state == nil)

        # do not reply, sit here (and wait for cancellation probably)

      else # vanilla reply

        (do_unpersist || return) if delete
          # remove expression from storage

        if h.parent_id

          @context.storage.put_msg(
            'reply',
            'fei' => h.parent_id,
            'workitem' => workitem.merge!('fei' => h.fei),
            'updated_tree' => h.updated_tree) # nil most of the time
        else

          @context.storage.put_msg(
            h.forgotten ? 'ceased' : 'terminated',
            'wfid' => h.fei['wfid'],
            'fei' => h.fei,
            'workitem' => workitem)
        end
      end
    end

    # Wraps #reply (does the administrative part of the reply work).
    #
    def do_reply(msg)

      @msg = Ruote.fulldup(msg)
        # keeping the message, for 'retry' in collision cases

      workitem = msg['workitem']
      fei = workitem['fei']

      if ut = msg['updated_tree']
        ct = tree.dup
        ct.last[Ruote::FlowExpressionId.child_id(fei)] = ut
        update_tree(ct)
      end

      removed = h.children.delete(fei)
        # accept without any check ?

      (h['flanks'] ||= []) << fei if msg['flanking']

      if msg['flanking'] and (not removed)
        #
        # it's a timer
        #
        puts 'x' * 80
        # persist or retry
      end

      if h.state == 'paused'

        (h['paused_replies'] ||= []) << msg

        do_persist

      elsif h.state != nil # failing or timing out ...

        if h.children.size < 1
          reply_to_parent(workitem)
        else
          persist_or_raise # for the updated h.children
        end

      else # vanilla reply

        reply(workitem)
      end
    end

    # (only makes sense for the participant expression though)
    #
    alias :do_receive :do_reply

    # A default implementation for all the expressions.
    #
    def reply(workitem)

      reply_to_parent(workitem)
    end

    # The raw handling of messages passed to expressions (the fine handling
    # is done in the #cancel method).
    #
    def do_cancel(msg)

      @msg = Ruote.fulldup(msg)

      flavour = msg['flavour']

      return if h.state == 'cancelling' && flavour != 'kill'
        # cancel on cancel gets discarded

      return if h.state == 'failed' && flavour == 'timeout'
        # do not timeout expressions that are "in error" (failed)

      @msg = Ruote.fulldup(msg)

      h.state = case flavour
        when 'kill' then 'dying'
        when 'timeout' then 'timing_out'
        else 'cancelling'
      end

      h.applied_workitem['fields']['__timed_out__'] = [
        h.fei, Ruote.now_to_utc_s, tree.first, compile_atts
      ] if h.state == 'timing_out'

      if h.state == 'cancelling'

        if t = msg['on_cancel']

          h.on_cancel = t

        elsif hra = msg['re_apply']

          hra = {} if hra == true

          h.on_re_apply = hra['tree'] || tree

          if fs = hra['fields']
            h.applied_workitem['fields'] = fs
          end
          if mfs = hra['merge_in_fields']
            h.applied_workitem['fields'].merge!(mfs)
          end
        end
      end

      cancel(flavour)
    end

    # This default implementation cancels all the [registered] children
    # of this expression.
    #
    def cancel(flavour)

      (h.flanks || []).each do |flank_fei|

        @context.storage.put_msg(
          'cancel',
          'fei' => flank_fei,
          'parent_id' => h.fei,
            # indicating that this is a "cancel child", well...
          'flavour' => flavour)
      end

      return reply_to_parent(h.applied_workitem) if h.children.empty?
        #
        # there are no children, nothing to cancel, let's just reply to
        # the parent expression

      do_persist || return
        #
        # before firing the cancel message to the children
        #
        # if the do_persist returns false, it means it failed, implying this
        # expression is stale, let's return, thus discarding this cancel message

      children.each do |child_fei|
        #
        # let's send a cancel message to each of the children
        #
        # maybe some of them are gone or have not yet been applied, anyway,
        # the messages are sent

        @context.storage.put_msg(
          'cancel',
          'fei' => child_fei,
          'parent_id' => h.fei, # indicating that this is a "cancel child"
          'flavour' => flavour)
      end
    end

    # Called when handling an on_error, will place itself in a 'failing' state
    # and cancel the children (when the reply from the children comes back,
    # the on_error will get triggered).
    #
    def do_fail(msg)

      @msg = Ruote.fulldup(msg)

      @h['state'] = 'failing'
      @h['applied_workitem'] = msg['workitem']

      if h.children.size < 1
        reply_to_parent(@h['applied_workitem'])
      else
        persist_or_raise
        h.children.each { |i| @context.storage.put_msg('cancel', 'fei' => i) }
      end
    end

    # Expression received a "pause" message. Will put the expression in the
    # "paused" state and then pass the message to the children.
    #
    # If the expression is in a non-nil state (failed, timed_out, ...), the
    # message will be ignored.
    #
    def do_pause(msg)

      return if h.state != nil

      h['state'] = 'paused'

      do_persist || return

      h.children.each { |i|
        @context.storage.put_msg('pause', 'fei' => i)
      } unless msg['breakpoint']
    end

    # Will "unpause" the expression (if it was paused), and trigger any
    # 'paused_replies' (replies that came while the expression was paused).
    #
    def do_resume(msg)

      return if h.state != 'paused'

      h['state'] = nil
      replies = h.delete('paused_replies') || []

      do_persist || return

      h.children.each { |i| @context.storage.put_msg('resume', 'fei' => i) }
        # resume children

      replies.each { |m| @context.storage.put_msg(m.delete('action'), m) }
        # trigger replies
    end

    #--
    # misc
    #++

    # Launches a subprocesses (usually called from the #apply of certain
    # expression implementations.
    #
    def launch_sub(pos, subtree, opts={})

      i = h.fei.merge(
        'subid' => Ruote.generate_subid(h.fei.inspect),
        'expid' => pos)

      #p '=== launch_sub ==='
      #p [ :launcher, h.fei['expid'], h.fei['subid'], h.fei['wfid'] ]
      #p [ :launched, i['expid'], i['subid'], i['wfid'] ]

      forget = opts[:forget]

      register_child(i) unless forget

      variables = (
        forget ? compile_variables : {}
      ).merge!(opts[:variables] || {})

      @context.storage.put_msg(
        'launch',
        'fei' => i,
        'parent_id' => forget ? nil : h.fei,
        'tree' => subtree,
        'workitem' => opts[:workitem] || h.applied_workitem,
        'variables' => variables,
        'forgotten' => forget)
    end

    # Returns true if the given fei points to an expression in the parent
    # chain of this expression.
    #
    def ancestor?(fei)

      fei = fei.to_h if fei.respond_to?(:to_h)

      return false unless h.parent_id
      return true if h.parent_id == fei

      parent.ancestor?(fei)
    end

    # Given an error, returns the on_error registered for it, or nil if none.
    #
    def local_on_error(err)

      if h.on_error.is_a?(String) or Ruote.is_tree?(h.on_error)

        return h.on_error
      end

      if h.on_error.is_a?(Array)

        # all for the 'on_error' expression
        # see test/functional/eft_38_

        h.on_error.each do |oe|

          return oe.last if oe.first.nil?

          crit = Ruote.regex_or_s(oe.first)
          return oe.last if crit.match(err['message'])
          return oe.last if crit.match(err['class'])
        end
      end

      nil
    end

    # Looks up "on_error" attribute locally and in the parent expressions,
    # if any.
    #
    def lookup_on_error(err)

      if local_on_error(err)
        return self
      end
      if par = parent
        return par.lookup_on_error(err)
      end

      nil
    end

    # Looks up parent with on_error attribute and triggers it
    #
    def handle_on_error(msg, error)

      return false if h.state == 'failing'

      err = {
        'fei' => fei,
        'at' => Ruote.now_to_utc_s,
        'class' => error.class.to_s,
        'message' => error.message,
        'trace' => error.backtrace
      }

      oe_parent = lookup_on_error(err)

      return false unless oe_parent
        # no parent with on_error attribute found

      handler = oe_parent.local_on_error(err).to_s

      return false if handler == ''
        # empty on_error handler nullifies ancestor's on_error

      workitem = msg['workitem']
      workitem['fields']['__error__'] = err

      @context.storage.put_msg(
        'fail',
        'fei' => oe_parent.h.fei,
        'workitem' => workitem)

      true # yes, error is being handled.
    end

    #--
    # TREE
    #++

    # Returns the current version of the tree (returns the updated version
    # if it got updated.
    #
    def tree

      h.updated_tree || h.original_tree
    end

    # Updates the tree of this expression
    #
    #   update_tree(t)
    #
    # will set the updated tree to t
    #
    #   update_tree
    #
    # will copy (deep copy) the original tree as the updated_tree.
    #
    # Adding a child to a sequence expression :
    #
    #   seq.update_tree
    #   seq.updated_tree[2] << [ 'participant', { 'ref' => 'bob' }, [] ]
    #   seq.do_persist
    #
    def update_tree(t=nil)

      h.updated_tree = t || Ruote.fulldup(h.original_tree)
    end

    # Returns the name of this expression, like 'sequence', 'participant',
    # 'cursor', etc...
    #
    def name

      tree[0]
    end

    # Returns the attributes of this expression (like { 'ref' => 'toto' } or
    # { 'timeout' => '2d' }.
    #
    def attributes

      tree[1]
    end

    # Returns the "AST" view on the children of this expression...
    #
    def tree_children

      tree[2]
    end

    protected

    # Returns a Graphviz dot string representing this expression (and its
    # children).
    #
    def to_dot(opts)

      i = fei()

      label = "#{[ i.wfid, i.subid, i.expid].join(' ')} #{tree.first}"
      label += " (#{h.state})" if h.state

      a = []
      a << "\"#{i.to_storage_id}\" [ label=\"#{label}\" ];"

      # parent

      if h.parent_id
        a << "\"#{i.to_storage_id}\" -> \"#{parent_id.to_storage_id}\";"
      end

      # children

      h.children.each do |cfei|
        a << "\"#{i.to_storage_id}\" -> \"#{Ruote.to_storage_id(cfei)}\";"
      end

      a
    end

    # Used locally but also by ConcurrenceExpression, when preparing children
    # before they get applied.
    #
    def pre_apply_child(child_index, workitem, forget)

      child_fei = h.fei.merge(
        'expid' => "#{h.fei['expid']}_#{child_index}",
        'subid' => Ruote.generate_subid(h.fei.inspect))

      h.children << child_fei unless forget

      msg = {
        'fei' => child_fei,
        'tree' => tree.last[child_index],
        'parent_id' => forget ? nil : h.fei,
        'variables' => forget ? compile_variables : nil,
        'workitem' => workitem
      }
      msg['forgotten'] = true if forget

      msg
    end

    # Used by expressions when, well, applying a child expression of theirs.
    #
    def apply_child(child_index, workitem, forget=false)

      msg = pre_apply_child(child_index, workitem, forget)

      persist_or_raise unless forget
        # no need to persist the parent (this) if the child is to be forgotten

      @context.storage.put_msg('apply', msg)
    end

    # Some expressions have to keep track of their (instantiated) children,
    # this method does the registration (of the child's fei).
    #
    def register_child(fei)

      h.children << fei
      persist_or_raise
    end

    # Called to check if the expression has a :tag attribute. If yes,
    # will register the tag in a variable (and in the workitem).
    #
    def consider_tag

      if h.tagname = attribute(:tag)

        set_variable(h.tagname, h.fei)

        Ruote::Workitem.add_tag(h.applied_workitem, h.tagname)

        @context.storage.put_msg(
          'entered_tag',
          'tag' => h.tagname,
          'fei' => h.fei,
          'workitem' => h.applied_workitem)
      end
    end

    # Reads the :timeout and :timers attributes and schedule as necessary.
    #
    def consider_timers

      h.has_timers = (attribute(:timers) || attribute(:timeout)) != nil
        # to enforce pdef defined timers vs participant defined timers

      timers = (attribute(:timers) || '').split(/,/)

      if to = attribute(:timeout)
        to = to.strip
        timers << "#{to}: timeout" unless to == ''
      end

      timers.each do |t|

        after, action = if t.is_a?(String)
          i = t.rindex(':')
          [ t[0..i - 1], t[i + 1..-1] ]
        else
          t
        end

        after = after.strip
        action = action.strip

        next if after == ''

        msg = if action == 'timeout'
          { 'action' => 'cancel',
            'fei' => h.fei,
            'flavour' => 'timeout' }
        else
          { 'action' => 'apply',
            'wfid' => h.fei['wfid'],
            'expid' => h.fei['expid'],
            'parent_id' => h.fei,
            'lost' => true,
            'tree' => [ action, {}, [] ],
            'workitem' => h.applied_workitem }
        end

        (h.timers ||= []) <<
          [ @context.storage.put_schedule('at', h.fei, after, msg), action ]
      end
    end

    # (Called by trigger_on_cancel & co)
    #
    def supplant_with(tree, opts)

      # at first, nuke self

      r = try_unpersist

      raise(
        "failed to remove exp to supplant "+
        "#{Ruote.to_storage_id(h.fei)} #{tree.first}"
      ) if r.respond_to?(:keys)

      # then re-apply

      if t = opts['trigger']
        tree[1]['_triggered'] = t.to_s
      end

      @context.storage.put_msg(
        'apply',
        { 'fei' => h.fei,
          'parent_id' => h.parent_id,
          'tree' => tree,
          'workitem' => h.applied_workitem,
          'variables' => h.variables
        }.merge!(opts))
    end

    # 'on_{error|timeout|cancel|re_apply}' triggering
    #
    def trigger(on, workitem)

      handler = if on == 'on_error'
        local_on_error(h.applied_workitem['fields']['__error__'])
      else
        h[on]
      end

      new_tree = handler.is_a?(String) ? [ handler, {}, [] ] : handler

      if on == 'on_error' or on == 'on_timeout'

        case handler

          when 'redo', 'retry'

            new_tree = tree

          when 'undo', 'pass'

            h.state = 'failed'
            reply_to_parent(workitem)

            return # let's forget this error

          when CommandExpression::REGEXP

            hh = handler.split(' ')
            command = hh.first
            step = hh.last
              # 'jump to shark' or 'jump shark', ...

            h.state = nil
            workitem['fields'][CommandMixin::F_COMMAND] = [ command, step ]

            reply(workitem)

            return # we're dealing with it
        end
      end

      supplant_with(new_tree, 'trigger' => on)
    end
  end
end

