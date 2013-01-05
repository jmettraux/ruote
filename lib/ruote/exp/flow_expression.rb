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
  #
  # == the states of an expression
  #
  # === nil
  # the normal state
  #
  # === 'cancelling'
  # the expression and its children are getting cancelled
  #
  # === 'dying'
  # the expression and its children are getting killed
  #
  # === 'failed'
  # the expression has finishing
  #
  # === 'failing'
  # the expression just failed and it's cancelling its children
  #
  # === 'timing_out'
  # the expression just timedout and it's cancelling its children
  #
  # === 'paused'
  # the expression is paused, it will store downstream messages and play
  # them only when a 'resume' message comes from upstream.
  #
  class FlowExpression

    include Ruote::WithH
    include Ruote::WithMeta

    require 'ruote/exp/ro_attributes'
    require 'ruote/exp/ro_filters'
    require 'ruote/exp/ro_on_x'
    require 'ruote/exp/ro_persist'
    require 'ruote/exp/ro_timers'
    require 'ruote/exp/ro_variables'

    COMMON_ATT_KEYS = %w[
      if unless
      forget lose flank
      timeout timers
      on_error on_cancel on_timeout
    ]

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
    h_reader :on_terminate

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
      h.on_terminate ||= attribute(:on_terminate)
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

    # Returns the workflow instance id of the workflow this expression
    # belongs to.
    #
    def wfid

      h.fei['wfid']
    end

    # Returns the Ruote::FlowExpressionIf of the parent expression, or nil
    # if there is no parent expression.
    #
    def parent_id

      h.parent_id ?
        Ruote::FlowExpressionId.new(h.parent_id) :
        nil
    end

    # Returns the child_id for this expression. (The rightmost part of the
    # fei.expid).
    #
    def child_id

      fei.child_id
    end

    # Fetches the parent expression, or returns nil if there is no parent
    # expression.
    #
    def parent

      h.parent_id ?
        Ruote::Exp::FlowExpression.fetch(@context, h.parent_id) :
        nil
    end

    # An expensive method, looks up all the expressions with the same wfid
    # in the storage (for some storages this is not expensive at all),
    # and determine the root of this expression.
    # It does this by recursively going from an expression to its parent,
    # starting with this expression. The root is when the parent can't be
    # reached.
    #
    # By default, this method will always return an expression, but if
    # stubborn is set to true and the top expression points to a gone parent
    # then nil will be returned.
    # The default (stubborn=true) is probably what you want anyway.
    #
    def root(stubborn=false)

      previous = nil
      current = @h

      exps = @context.storage.find_expressions(
        @h['fei']['wfid']
      ).each_with_object({}) { |exp, h|
        h[exp['fei']] = exp
      }

      while current && current['parent_id']
        previous = current
        current = exps[current['parent_id']]
      end

      current ||= previous unless stubborn

      current ? Ruote::Exp::FlowExpression.from_h(@context, current) : nil
    end

    # Returns the fei of the root expression of this expression.
    # The result is an instance of Ruote::FlowExpressionId.
    #
    # Uses #root behind the scenes, hence the stubborn option.
    #
    def root_id(stubborn=false)

      root(stubborn).fei
    end

    # Concurrent expressions (expressions that apply more than one child
    # at a time) are supposed to return true here.
    #
    def is_concurrent?

      false
    end

    # Turns this FlowExpression instance into a Hash (well, just hands back
    # the base hash behind it).
    #
    def to_h

      @h
    end

    # Returns a one-off Ruote::Workitem instance (the applied workitem).
    #
    def applied_workitem

      @awi ||= Ruote::Workitem.new(h.applied_workitem)
    end

    # Given an index, returns the child fei (among the currently registered
    # children feis) whose fei.expid ends with this index (whose child_id
    # is equal to that index).
    #
    # Returns nil if not found or a child fei as a Hash.
    #
    def cfei_at(i)

      children.find { |cfei| Ruote.extract_child_id(cfei) == i }
    end

    # Returns the list of child_ids (last part of the fei.expid) for the
    # currently registered (active) children.
    #
    def child_ids

      children.collect { |cfei| Ruote.extract_child_id(cfei) }
    end

    # Instantiates expression back from hash.
    #
    def self.from_h(context, h)

      return self.new(nil, h) unless context

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

      n = context.storage.class.name.match(/Couch/) ? 3 : 1
        #
      n.times do |i|
        if fexp = fetch(context, msg['fei']); break; end
        sleep 0.028 unless i == (n - 1)
      end
        #
        # Simplify that once ruote-couch behaves

      fexp.do(action, msg) if fexp
    end

    # Wraps a call to "apply", "reply", etc... Makes sure to set @msg
    # with a deep copy of the msg before.
    #
    def do(action, msg)

      @msg = Ruote.fulldup(msg)

      send("do_#{action}", msg)
    end

    # Called by the worker when it has just created this FlowExpression and
    # wants to apply it.
    #
    def do_apply(msg)

      if msg['state'] == 'paused'

        return pause_on_apply(msg)
      end

      if msg['flavour'].nil? && (aw = attribute(:await))

        return await(aw, msg)
      end

      unless Condition.apply?(attribute(:if), attribute(:unless))

        return do_reply_to_parent(h.applied_workitem)
      end

      pi = h.parent_id
      reply_immediately = false

      if attribute(:scope).to_s == 'true'

        h.variables ||= {}
      end

      if attribute(:forget).to_s == 'true'

        h.variables = compile_variables
        h.parent_id = nil
        h.forgotten = true

        reply_immediately = true

      elsif attribute(:lose).to_s == 'true'

        h.lost = true

      elsif msg['flanking'] or (attribute(:flank).to_s == 'true')

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

    # Called by #do_apply when msg['state'] == 'paused'. Covers the
    # "apply/launch it but it's immediately paused" case. Freezes the
    # apply message in h.paused_apply and saves the expression.
    #
    def pause_on_apply(msg)

      msg['state'] = nil

      h.state = 'paused'
      h.paused_apply = msg

      persist_or_raise
    end

    # If the expression has an :await attribute, the expression gets
    # into a special "awaiting" state until the condition in the value
    # of :await gets triggered and the trigger calls resume on the
    # expression.
    #
    def await(att, msg)

      action, condition =
        Ruote::Exp::AwaitExpression.extract_await_ac(:await => att)

      raise ::ArgumentError.new(
        ":await does not understand #{att.inspect}"
      ) if action == nil

      msg.merge!('flavour' => 'awaiting')

      h.state = 'awaiting'
      h.paused_apply = msg

      persist_or_raise

      @context.tracker.add_tracker(
        h.fei['wfid'],
        action,
        Ruote.to_storage_id(h.fei),
        condition,
        { '_auto_remove' => true,
          'action' => 'resume',
          'fei' => h.fei,
          'flavour' => 'awaiting' })
    end

    # FlowExpression call this method when they're done and they want their
    # parent expression to take over (it will end up calling the #reply of
    # the parent expression).
    #
    # Expression implementations are free to override this method.
    # The common behaviour is in #do_reply_to_parent.
    #
    def reply_to_parent(workitem, delete=true)

      do_reply_to_parent(workitem, delete)
    end

    # The essence of the reply_to_parent job...
    #
    def do_reply_to_parent(workitem, delete=true)

      # propagate the cancel "flavour" back, so that one can know
      # why a branch got cancelled.

      flavour = if @msg.nil?
        nil
      elsif @msg['action'] == 'cancel'
        @msg['flavour'] || 'cancel'
      elsif h.state.nil?
        nil
      else
        @msg['flavour']
      end

      # deal with the timers and the schedules

      %w[ timeout_schedule_id job_id ].each do |sid|
        @context.storage.delete_schedule(h[sid]) if h[sid]
      end
        #
        # legacy schedule ids, to be removed for ruote 2.4.0

      @context.storage.delete_schedule(h.schedule_id) if h.schedule_id
        #
        # time-driven exps like cron, wait and once now all use h.schedule_id

      h.timers.each do |schedule_id, action|
        @context.storage.delete_schedule(schedule_id)
      end if h.timers

      # cancel flanking expressions if any

      cancel_flanks(h.state == 'dying' ? 'kill' : nil)

      # trigger or vanilla reply

      if h.state == 'failing' # on_error is implicit (#do_fail got called)

        trigger('on_error', workitem)

      elsif h.state == 'cancelling' && h.on_cancel

        trigger('on_cancel', workitem)

      elsif h.state == 'cancelling' && h.on_re_apply

        trigger('on_re_apply', workitem)

      elsif h.state == 'timing_out' && h.on_timeout

        trigger('on_timeout', workitem)

      elsif h.state == nil && h.on_reply

        trigger('on_reply', workitem)

      elsif h.flanking && h.state.nil?
        #
        # do vanish

        do_unpersist

      elsif h.lost && h.state.nil?
        #
        # do not reply, sit here (and wait for cancellation probably)

        do_persist

      elsif h.trigger && workitem['fields']["__#{h.trigger}__"]
        #
        # the "second take"

        trigger(h.trigger, workitem)

      else # vanilla reply

        filter(workitem) if h.state.nil?

        f = h.state.nil? && attribute(:vars_to_f)
        Ruote.set(workitem['fields'], f, h.variables) if f

        workitem['sub_wf_name'] = @h.applied_workitem['sub_wf_name']
        workitem['sub_wf_revision'] = @h.applied_workitem['sub_wf_revision']

        leave_tag(workitem) if h.tagname

        (do_unpersist || return) if delete
          # remove expression from storage

        if h.parent_id && ! h.attached

          @context.storage.put_msg(
            'reply',
            'fei' => h.parent_id,
            'workitem' => workitem.merge!('fei' => h.fei),
            'updated_tree' => h.updated_tree, # nil most of the time
            'flavour' => flavour)

        else

          @context.storage.put_msg(
            (h.forgotten || h.attached) ? 'ceased' : 'terminated',
            'wfid' => h.fei['wfid'],
            'fei' => h.fei,
            'workitem' => workitem,
            'variables' => h.variables,
            'flavour' => flavour)

          if
            h.state.nil? &&
            h.on_terminate == 'regenerate' &&
            ! (h.forgotten || h.attached)
          then
            @context.storage.put_msg(
              'regenerate',
              'wfid' => h.fei['wfid'],
              'tree' => h.original_tree,
              'workitem' => workitem,
              'variables' => h.variables,
              'flavour' => flavour)
              #'stash' =>
          end
        end
      end
    end

    # Wraps #reply (does the administrative part of the reply work).
    #
    def do_reply(msg)

      workitem = msg['workitem']
      fei = workitem['fei']

      removed = h.children.delete(fei)
        # accept without any check ?

      if msg['flanking']

        (h.flanks ||= []) << fei

        if (not removed) # then it's a timer

          do_persist
          return
        end
      end

      if ut = msg['updated_tree']

        ct = tree.dup
        ct.last[Ruote::FlowExpressionId.child_id(fei)] = ut
        update_tree(ct)
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

      flavour = msg['flavour']

      return if h.state == 'cancelling' && flavour != 'kill'
        # cancel on cancel gets discarded

      return if h.state == 'failed' && flavour == 'timeout'
        # do not timeout expressions that are "in error" (failed)

      h.state = case flavour
        when 'kill' then 'dying'
        when 'timeout' then 'timing_out'
        else 'cancelling'
      end

      if h.state == 'timing_out'

        h.applied_workitem['fields']['__timed_out__'] = [
          h.fei, Ruote.now_to_utc_s, tree.first, compile_atts
        ]

      elsif h.state == 'cancelling'

        if t = msg['on_cancel']

          h.on_cancel = t

        elsif ra_opts = msg['re_apply']

          ra_opts = {} if ra_opts == true
          ra_opts['tree'] ||= tree

          h.on_re_apply = ra_opts
        end
      end

      cancel(flavour)
    end

    # Emits a cancel message for each flanking expression (if any).
    #
    def cancel_flanks(flavour)

      return unless h.flanks

      h.flanks.each do |flank_fei|

        @context.storage.put_msg(
          'cancel',
          'fei' => flank_fei,
          'parent_id' => h.fei,
            # indicating that this is a "cancel child", well...
          'flavour' => flavour)
      end
    end

    # This default implementation cancels all the [registered] children
    # of this expression.
    #
    def cancel(flavour)

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

      @h['state'] = 'failing'
      @h['applied_workitem'] = msg['workitem']

      if h.children.size < 1

        reply_to_parent(@h['applied_workitem'])

      else

        flavour = msg['immediate'] ? 'kill' : nil

        persist_or_raise

        h.children.each do |i|
          @context.storage.put_msg('cancel', 'fei' => i, 'flavour' => flavour)
        end
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

      return unless h.state == 'paused' || h.state == 'awaiting'

      h['state'] = nil

      m = h.delete('paused_apply')
      return do_apply(m) if m
        # if it's a paused apply, pipe it directly to #do_apply

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

      if ci = opts[:child_id]
        i['subid'] = "#{i['subid']}k#{ci}"
      end

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

      tag = attribute(:tag)

      return unless tag && tag.strip.size > 0

      h.tagname = tag
      h.full_tagname = applied_workitem.tags.join('/')

      return if h.trigger
        #
        # do not consider tags when the tree is applied for an
        # on_x trigger

      h.full_tagname = (applied_workitem.tags + [ tag ]).join('/')

      set_variable(h.tagname, h.fei)
      set_variable('/' + h.full_tagname, h.fei)

      applied_workitem.send(:add_tag, h.tagname)

      @context.storage.put_msg(
        'entered_tag',
        'tag' => h.tagname,
        'full_tag' => h.full_tagname,
        'fei' => h.fei,
        'workitem' => h.applied_workitem)
    end

    # Called when the expression is about to reply to its parent and wants
    # to get rid of its tags.
    #
    def leave_tag(workitem)

      unset_variable(h.tagname)

      Ruote::Workitem.new(workitem).send(:remove_tag, h.tagname)

      @context.storage.put_msg(
        'left_tag',
        'tag' => h.tagname,
        'full_tag' => h.full_tagname,
        'fei' => h.fei,
        'workitem' => workitem)

      return unless h.full_tagname # for backward compatibility

      r = root

      return unless r && r.variables # might happen

      r.variables.delete(h.full_tagname)

      state = case (h.trigger || h.state)

        when 'on_cancel' then 'cancelled'
        when 'on_error' then 'failed'
        when 'on_timeout' then 'timed out'
        when 'on_re_apply' then nil

        when 'cancelling' then 'cancelled'
        when 'dying' then 'killed'

        else nil
      end

      (r.variables['__past_tags__'] ||= []) << [
        h.full_tagname,
        fei.sid,
        state,
        Ruote.now_to_utc_s,
        Ruote.fulldup(h.variables)
          # not fullduping here triggers a segfault at some point with YAJL
      ]

      r.do_persist unless r.fei == self.fei
    end
  end
end

