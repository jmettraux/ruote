#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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
  # TODO : document me
  #
  class FlowExpression

    include Ruote::WithH
    include Ruote::WithMeta

    require 'ruote/exp/ro_attributes'
    require 'ruote/exp/ro_variables'

    attr_reader :context
    attr_reader :h

    h_reader :variables
    h_reader :created_time
    h_reader :original_tree
    h_reader :updated_tree

    h_reader :state

    h_reader :on_error
    h_reader :on_cancel
    h_reader :on_timeout

    def initialize (context, h)

      @context = context

      @h = h
      class << h
        include Ruote::HashDot
      end

      h._id ||= fei.to_storage_id
      h['type'] ||= 'expressions'
      h.name ||= self.class.expression_names.first
      h.children ||= []
      h.applied_workitem['fei'] = h.fei
      h.created_time ||= Ruote.now_to_utc_s

      h.on_cancel ||= attribute(:on_cancel)
      h.on_error ||= attribute(:on_error)
      h.on_timeout ||= attribute(:on_timeout)
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

    #--
    # PERSISTENCE
    #++

    def persist

      @context.storage.put(@h)
    end

    def unpersist

      @context.storage.delete(@h)

      if h.has_error

        err = @context.storage.get(
          'errors', Ruote::FlowExpressionId.to_storage_id(h.fei))

        @context.storage.delete(err) if err
      end
    end

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

      fexp = context.storage.get(
        'expressions', Ruote::FlowExpressionId.new(fei).to_storage_id)

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

    def do_apply

      if Condition.skip?(attribute(:if), attribute(:unless))

        return reply_to_parent(h.applied_workitem)
      end

      if attribute(:forget).to_s == 'true'

        i = h.parent_id
        wi = Ruote.fulldup(h.applied_workitem)

        h.variables = compile_variables
        h.parent_id = nil
        h.forgotten = true

        @context.storage.put_msg(
          'reply', 'fei' => i, 'workitem' => wi)
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

        @context.storage.delete_at_schedule(h.timeout_schedule_id)
      end

      state = h.state

      if state == 'failing' # on_error is implicit (#fail got called)

        trigger('on_error', workitem)

      elsif (state == 'cancelling') and h.on_cancel

        trigger('on_cancel', workitem)

      elsif (state == 'timing_out') and h.on_timeout

        trigger('on_timeout', workitem)

      else # vanilla reply

        unpersist if delete

        if h.parent_id

          workitem['fei'] = h.fei

          @context.storage.put_msg(
            'reply',
            'fei' => h.parent_id,
            'workitem' => workitem,
            'updated_tree' => h.updated_tree) # nil most of the time
        else

          @context.storage.put_msg(
            h.forgotten ? 'ceased' : 'terminated',
            'wfid' => h.fei['wfid'],
            'workitem' => workitem)
        end
      end
    end

    def do_reply (msg)

      workitem = msg['workitem']
      fei = workitem['fei']

      if ut = msg['updated_tree']
        ct = tree.dup
        ct.last[Ruote::FlowExpressionId.child_id(fei)] = ut
        update_tree(ct)
      end

      h.children.delete(fei)

      if h.state != nil

        if h.children.size < 1
          reply_to_parent(workitem)
        else
          persist # for the updated h.children
        end

      else

        reply(workitem)
      end
    end

    # A default implementation for all the expressions.
    #
    def reply (workitem)

      reply_to_parent(workitem)
    end

    # Cancels the expression (the whole branch) and makes sure it's re-applied
    # (by riding the on_cancel attribute).
    #
    def re_apply

      h.on_cancel = tree
      persist

      @context.storage.put_msg('cancel', 'fei' => h.fei)
    end

    def do_cancel (msg)

      flavour = msg['flavour']

      return if h.state == 'failed' and flavour == 'timeout'
        # do not timeout expressions that are "in error" (failed)

      h.state = case flavour
        when 'kill' then 'dying'
        when 'timeout' then 'timing_out'
        else 'cancelling'
      end

      h.applied_workitem['fields']['__timed_out__'] = [
        h.fei, Ruote.now_to_utc_s
      ] if h.state == 'timing_out'

      cancel(flavour)
    end

    # This default implementation cancels all the [registered] children
    # of this expression.
    #
    def cancel (flavour)

      persist
        # before firing the cancel message to the children

      h.children.each do |cfei|

        @context.storage.put_msg(
          'cancel',
          'fei' => cfei,
          'parent_id' => h.fei, # indicating that this is a "cancel child"
          'flavour' => flavour)
      end
    end

    def do_fail (msg)

      @h['state'] = 'failing'
      persist

      h.children.each { |i| @context.storage.put_msg('cancel', 'fei' => i) }
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
        'workitem' => h.applied_workitem,
        'variables' => variables)
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
        parent.lookup_on_error
      else
        nil
      end
    end

    # Looks up parent with on_error attribute and triggers it
    #
    def handle_on_error

      return false if h.state == 'failing'

      oe_parent = lookup_on_error

      return false unless oe_parent
        # no parent with on_error attribute found

      handler = oe_parent.on_error.to_s

      return false if handler == ''
        # empty on_error handler nullifies ancestor's on_error

      @context.storage.put_msg(
        'fail',
        'fei' => oe_parent.h.fei,
        'error_fei' => h.fei)

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
    #   seq.persist
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

    protected

    def apply_child (child_index, workitem, forget=false)

      child_fei = h.fei.merge(
        'expid' => "#{h.fei['expid']}_#{child_index}")

      h.children << child_fei unless forget

      persist

      @context.storage.put_msg(
        'apply',
        'fei' => child_fei,
        'tree' => tree.last[child_index],
        'parent_id' => forget ? nil : h.fei,
        'variables' => forget ? compile_variables : nil,
        'workitem' => workitem,
        'forgotten' => forget)
    end

    # Generates a sub_wfid, without hitting storage.
    #
    # There's a better implementation for sure...
    #
    def get_next_sub_wfid

      i = [
        $$, Time.now.to_f.to_s, self.hash.to_s, @h['fei'].inspect
      ].join('-').hash

      (i < 0 ? "1#{i * -1}" : "0#{i}").to_s
    end

    def register_child (fei)

      h.children << fei
      persist
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

      h.timeout_at = Ruote.s_to_at(timeout)

      return if not(h.timeout_at) || h.timeout_at < Time.now.utc + 1.0

      h.timeout_schedule_id = @context.storage.put_at_schedule(
        h.fei,
        h.timeout_at,
        'action' => 'cancel',
        'fei' => h.fei,
        'flavour' => 'timeout')
    end

    # (Called by trigger_on_cancel & co)
    #
    def supplant_with (tree, opts)

      # at first, nuke self

      unpersist

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

    # if any on_cancel handler is present, will trigger it.
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

        if hon == 'redo'

          t = tree
        end
      end

      supplant_with(t, 'trigger' => on)
    end
  end
end

