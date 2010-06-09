#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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
require 'ruote/util/dollar'
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

    COMMON_ATT_KEYS = %w[
      if unless forget timeout on_error on_cancel on_timeout ]

    attr_reader :context
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

    def initialize (context, h)

      @context = context

      @msg = nil

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

    def h= (hash)
      @h = hash
      class << h
        include Ruote::HashDot
      end
    end

    def fei
      Ruote::FlowExpressionId.new(h.fei)
    end

    def parent_id
      h.parent_id ? Ruote::FlowExpressionId.new(h.parent_id) : nil
    end

    def parent
      Ruote::Exp::FlowExpression.fetch(@context, h.parent_id)
    end

    # Turns this FlowExpression instance into a Hash (well, just hands back
    # the base hash behind it.
    #
    def to_h

      @h
    end

    # Instantiates expression back from hash.
    #
    def self.from_h (context, h)

      exp_class = context.expmap.expression_class(h['name'])

      exp_class.new(context, h)
    end

    # Fetches an expression from the storage and readies it for service.
    #
    def self.fetch (context, fei)

      return nil if fei.nil?

      fexp = context.storage.get('expressions', Ruote.to_storage_id(fei))

      fexp ? from_h(context, fexp) : nil
    end

    #--
    # META
    #++

    # Keeping track of names and aliases for the expression
    #
    def self.names (*exp_names)

      exp_names = exp_names.collect { |n| n.to_s }
      meta_def(:expression_names) { exp_names }
    end

    #--
    # apply/reply
    #++

    def self.do_action (context, msg)

      fei = msg['fei']
      action = msg['action']

      if action == 'reply' && fei['engine_id'] != context.engine_id

        ep = context.plist.lookup(fei['engine_id'])

        raise(
          "no EngineParticipant found under name '#{fei['engine_id']}'"
        ) unless ep

        ep.reply(fei, msg['workitem'])
        return
      end

      fexp = nil

      3.times do
        fexp = fetch(context, msg['fei'])
        break if fexp
        sleep 0.028
      end
        # this retry system is only useful with ruote-couch

      fexp.send("do_#{action}", msg) if fexp
    end

    def do_apply

      if not Condition.apply?(attribute(:if), attribute(:unless))

        return reply_to_parent(h.applied_workitem)
      end

      if attribute(:forget).to_s == 'true'

        i = h.parent_id
        wi = Ruote.fulldup(h.applied_workitem)

        h.variables = compile_variables
        h.parent_id = nil
        h.forgotten = true

        @context.storage.put_msg('reply', 'fei' => i, 'workitem' => wi)
      end

      consider_tag
      consider_timeout

      apply
    end

    def reply_to_parent (workitem, delete=true)

      if h.tagname

        unset_variable(h.tagname)

        @context.storage.put_msg(
          'left_tag', 'tag' => h.tagname, 'fei' => h.fei)
      end

      if h.timeout_schedule_id && h.state != 'timing_out'

        @context.storage.delete_schedule(h.timeout_schedule_id)
      end

      if h.state == 'failing' # on_error is implicit (#fail got called)

        trigger('on_error', workitem)

      elsif (h.state == 'cancelling') and h.on_cancel

        trigger('on_cancel', workitem)

      elsif (h.state == 'timing_out') and h.on_timeout

        trigger('on_timeout', workitem)

      else # vanilla reply

        #unpersist_or_raise if delete
        #try_unpersist if delete
        if delete
          do_unpersist || return
        end

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

    def do_reply (msg)

      @msg = Ruote.fulldup(msg)
        # keeping the message, for 'retry' in collision cases

      workitem = msg['workitem']
      fei = workitem['fei']

      if ut = msg['updated_tree']
        ct = tree.dup
        ct.last[Ruote::FlowExpressionId.child_id(fei)] = ut
        update_tree(ct)
      end

      h.children.delete(fei)
        # accept without any check ?

      if h.state != nil # failing or timing out ...

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
    def reply (workitem)

      reply_to_parent(workitem)
    end

    # The raw handling of messages passed to expressions (the fine handling
    # is done in the #cancel method).
    #
    def do_cancel (msg)

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
        h.fei, Ruote.now_to_utc_s
      ] if h.state == 'timing_out'

      if h.state == 'cancelling'

        if t = msg['on_cancel']

          h.on_cancel = t

        elsif hra = msg['re_apply']

          hra = {} if hra == true
          h.on_cancel = hra['tree'] || tree
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
    def cancel (flavour)

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

      children.each do |cfei|
        #
        # let's send a cancel message to each of the children
        #
        # maybe some of them are gone or have not yet been applied, anyway,
        # the message are sent

        @context.storage.put_msg(
          'cancel',
          'fei' => cfei,
          'parent_id' => h.fei, # indicating that this is a "cancel child"
          'flavour' => flavour)
      end

      #if ! children.find { |i| Ruote::Exp::FlowExpression.fetch(@context, i) }
      #  #
      #  # since none of the children could be found in the storage right now,
      #  # it could mean that all children are already done or it could mean
      #  # that they are not yet applied...
      #  #
      #  # just to be sure let's send a new cancel message to this expression
      #  #
      #  # it's very important, since if there is no child to cancel the parent
      #  # the flow might get stuck here
      #  @context.storage.put_msg(
      #    'cancel',
      #    'fei' => h.fei,
      #    'flavour' => flavour)
      #end
    end

    def do_fail (msg)

      @h['state'] = 'failing'
      @h['applied_workitem'] = msg['workitem']

      if h.children.size < 1
        reply_to_parent(@h['applied_workitem'])
      else
        persist_or_raise
        h.children.each { |i| @context.storage.put_msg('cancel', 'fei' => i) }
      end
    end

    #--
    # misc
    #++

    def launch_sub (pos, subtree, opts={})

      i = h.fei.dup
      i['sub_wfid'] = get_next_sub_wfid
      i['expid'] = pos

      #p '=== launch_sub ==='
      #p [ :launcher, h.fei['expid'], h.fei['sub_wfid'], h.fei['wfid'] ]
      #p [ :launched, i['expid'], i['sub_wfid'], i['wfid'] ]

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
    def ancestor? (fei)

      return false unless h.parent_id
      return true if h.parent_id == fei

      parent.ancestor?(fei)
    end

    # Looks up "on_error" attribute
    #
    def lookup_on_error

      if h.on_error

        self

      elsif h.parent_id

        par = parent
          # :( get_parent would probably be a better name for #parent

        unless par
          puts "~~"
          puts "parent gone for"
          p h.fei
          p h.parent_id
          p tree
          puts "~~"
        end

        par ? par.lookup_on_error : nil

      else

        nil
      end
    end

    # Looks up parent with on_error attribute and triggers it
    #
    def handle_on_error (msg, error)

      return false if h.state == 'failing'

      oe_parent = lookup_on_error

      return false unless oe_parent
        # no parent with on_error attribute found

      handler = oe_parent.on_error.to_s

      return false if handler == ''
        # empty on_error handler nullifies ancestor's on_error

      workitem = msg['workitem']

      workitem['fields']['__error__'] = [
        h.fei, Ruote.now_to_utc_s, error.class.to_s, error.message ]

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
    def update_tree (t=nil)
      h.updated_tree = t || Ruote.fulldup(h.original_tree)
    end

    def name
      tree[0]
    end

    def attributes
      tree[1]
    end

    def tree_children
      tree[2]
    end

    # A tiny class-bound counter used when generating subprocesses ids.
    #
    @@sub_wfid_counter = -1

    # Generates a sub_wfid, without hitting storage.
    #
    # There's a better implementation for sure...
    #
    def get_next_sub_wfid

      i = [
        $$, Time.now.to_f.to_s, self.hash.to_s, @h['fei'].inspect
      ].join('-').hash

      @@sub_wfid_counter = (@@sub_wfid_counter + 1) % 1000
      i = i * 1000 + (@@sub_wfid_counter)

      (i < 0 ? "1#{i * -1}" : "0#{i}").to_s
    end

    protected

    def to_dot (opts)

      i = fei()

      label = "#{[ i.wfid, i.sub_wfid, i.expid].join(" ")} #{tree.first}"
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

    def pre_apply_child (child_index, workitem, forget)

      child_fei = h.fei.merge('expid' => "#{h.fei['expid']}_#{child_index}")

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

    def apply_child (child_index, workitem, forget=false)

      msg = pre_apply_child(child_index, workitem, forget)

      persist_or_raise unless forget

      @context.storage.put_msg('apply', msg)
    end

    def register_child (fei)

      h.children << fei
      persist_or_raise
    end

    def consider_tag

      if h.tagname = attribute(:tag)

        set_variable(h.tagname, h.fei)

        @context.storage.put_msg(
          'entered_tag', 'tag' => h.tagname, 'fei' => h.fei)
      end
    end

    # Called by do_apply. Overriden in ParticipantExpression.
    #
    def consider_timeout

      do_schedule_timeout(attribute(:timeout))
    end

    # Called by consider_timeout (FlowExpression) and schedule_timeout
    # (ParticipantExpression).
    #
    def do_schedule_timeout (timeout)

      return unless timeout

      #h.timeout_at = Ruote.s_to_at(timeout)
      #return if not(h.timeout_at) || h.timeout_at < Time.now.utc + 1.0

      h.timeout_schedule_id = @context.storage.put_schedule(
        'at',
        h.fei,
        timeout,
        'action' => 'cancel',
        'fei' => h.fei,
        'flavour' => 'timeout')
    end

    # (Called by trigger_on_cancel & co)
    #
    def supplant_with (tree, opts)

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

    # 'on_{error|timeout|cancel}' triggering
    #
    def trigger (on, workitem)

      hon = h[on]

      t = hon.is_a?(String) ? [ hon, {}, [] ] : hon

      if on == 'on_error'

        if hon == 'redo'

          t = tree

        elsif hon == 'undo'

          h.state = 'failed'
          reply_to_parent(workitem)
          return
        end

      elsif on == 'on_timeout'

        t = tree if hon == 'redo'
      end

      supplant_with(t, 'trigger' => on)
    end
  end
end

