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

require 'ruote/util/ometa'
require 'ruote/util/dollar'
require 'ruote/engine/context'


module Ruote::Exp

  #
  # A simple timeout error. Only used when :on_timeout => 'error' for now.
  #
  class TimeoutError < RuntimeError
    def backtrace
      [ '---' ]
    end
  end

  #
  # The root class for all the expressions in Ruote.
  #
  # Contains lots of default behaviour, extending classes primarily
  # override #apply, #reply and #cancel.
  #
  class FlowExpression < Ruote::ObjectWithMeta

    include Ruote::EngineContext

    require 'ruote/exp/ro_tickets'
    require 'ruote/exp/ro_attributes'
    require 'ruote/exp/ro_variables'


    attr_accessor :fei
    attr_accessor :parent_id

    attr_reader :tagname

    attr_accessor :original_tree
    attr_reader :updated_tree

    attr_accessor :variables

    attr_reader :children

    attr_accessor :on_cancel
    attr_accessor :on_error
    attr_accessor :on_timeout

    attr_accessor :created_time
    attr_accessor :applied_workitem

    attr_reader :state

    attr_reader :modified_time

    COMMON_ATT_KEYS = %w[
      if unless timeout on_error on_cancel on_timeout forget
    ]

    def initialize (context, fei, parent_id, tree, variables, workitem)

      @context = context

      @fei = fei
      @parent_id = parent_id

      @original_tree = tree.dup
      @updated_tree = nil

      @state = nil # the default state of an 'active' expression
      @has_error = false

      @children = []

      @variables = variables

      @created_time = Time.now
      @modified_time = @created_time

      @applied_workitem = workitem.dup

      @on_cancel = attribute(:on_cancel)
      @on_error = attribute(:on_error)
      @on_timeout = attribute(:on_timeout)

      @tagname = nil

      @timeout_at = nil
      @timeout_job_id = nil
    end

    # Returns the parent expression of this expression instance.
    #
    def parent

      expstorage[@parent_id]
    end

    # This method is called by expool#apply_child and expool#launch_sub,
    # it helps an expression keep track of its currently active children.
    #
    def register_child (fei, do_persist=true)

      @children << fei
      persist if do_persist
    end

    # Returns true if the given fei points to an expression in the parent
    # chain of this expression.
    #
    def ancestor? (fei)

      return false unless @parent_id
      return true if @parent_id == fei
      parent.ancestor?(fei)
    end

    # Returns the root expression for this expression (top parent).
    #
    def root_expression

      @parent_id == nil ? self : parent.root_expression
    end

    #--
    # TREE
    #++

    # Returns the current version of the tree (returns the updated version
    # if it got updated.
    #
    def tree
      @updated_tree || @original_tree
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
      @updated_tree = t || Ruote.fulldup(@original_tree)
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

    # Given something like
    #
    #   sequence do
    #     participant 'alpha'
    #   end
    #
    # in the context of the participant expression
    #
    #   attribute_text()
    #
    # will yield 'alpha'.
    #
    def attribute_text (workitem=@applied_workitem)

      text = attributes.keys.find { |k| attributes[k] == nil }

      Ruote.dosub(text.to_s, self, workitem)
    end

    #--
    # APPLY / REPLY / CANCEL
    #++

    # Called directly by the expression pool.
    #
    def do_apply

      initial = Ruote.fulldup(self)

      if Condition.skip?(attribute(:if), attribute(:unless))

        pool.reply_to_parent(self, @applied_workitem)
        return
      end

      if attribute(:forget).to_s == 'true'

        pid = @parent_id
        forget
        pool.reply(@applied_workitem.dup, pid)
          # replying with a copy of the workitem is imperative since
          # the forgotten expression (branch) now executes 'in parallel'
      end

      consider_tag
      consider_timeout

      begin

        apply

      rescue Exception => e
        initial.context = @context
        initial.persist
        raise e
      end
    end

    # Called directly by the expression pool. See #reply for the (overridable)
    # default behaviour.
    #
    def do_reply (workitem)

      @children.delete(workitem.fei)
        # NOTE : check on size before/after ?

      if @state != nil # :failing, :cancelling or :dying

        if @children.size < 1
          reply_to_parent(workitem)
        else
          persist # for the updated @children
        end

      else

        reply(workitem)
      end
    end

    # Called directly by the expression pool. See #cancel for the (overridable)
    # default behaviour.
    #
    def do_cancel (flavour)

      return if @state == :failed and flavour == :timeout
        # do not timeout expressions that are "in error" (failed)

      @state = case flavour
        when :kill then :dying
        when :timeout then :timing_out
        else :cancelling
      end

      @applied_workitem.fields['__timed_out__'] = [ @fei, Time.now ] \
        if @state == :timing_out

      persist

      cancel(flavour)
    end

    # The default implementation : replies to the parent expression
    #
    def reply (workitem)

      reply_to_parent(workitem)
    end

    # This default implementation cancels all the [registered] children
    # of this expression.
    #
    def cancel (flavour)

      @children.each { |cfei| pool.cancel_expression(cfei, flavour) }
    end

    # Forces error handling by this expression.
    #
    def fail

      @state = :failing
      persist

      @children.each { |cfei| pool.cancel_expression(cfei, nil) }
    end

    # Nullifies the @parent_id and emits a :forgotten message
    #
    # This is used to forget an expression after it's been applied (see the
    # concurrence expression for example).
    #
    def forget

      wqueue.emit(:expressions, :forgotten, :fei => @fei, :parent => @parent_id)

      @variables = compile_variables
        # gather a copy of all the currently visible variables
        # else when @parent_id is cut, there is no looking back

      @parent_id = nil
        # cut the ombilical cord

      persist
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

    # Returns true if this expression is a a definition
    # (define, process_definition, set, ...)
    #
    def self.is_definition?

      false
    end

    # This method makes sure the calling class responds "true" to is_definition?
    # calls.
    #
    def self.is_definition

      meta_def(:is_definition?) { true }
    end

    #--
    # ON_CANCEL / ON_ERROR
    #++

    # Looks up an "on_" attribute
    #
    def lookup_on (type)

      if self.send("on_#{type}")
        self
      elsif @parent_id
        parent.lookup_on(type)
      else
        nil
      end
    end

    #--
    # SERIALIZATION
    #
    # making sure '@context' is not serialized
    #++

    def marshal_dump #:nodoc#

      iv = instance_variables
      iv.delete(:@context)
      iv.delete('@context')
      iv.inject({}) { |h, vn| h[vn] = instance_variable_get(vn); h }
    end

    def marshal_load (s) #:nodoc#

      s.each { |k, v| instance_variable_set(k, v) }
    end

    def to_yaml_properties #:nodoc#

      #l = super
      l = instance_variables.sort
        # behind the scenes ;-)

      l.delete(:@context)
      l.delete('@context')

      l
    end

    # Asks expstorage[s] to store/update persisted version of self.
    #
    def persist (probe=false)

      @modified_time = Time.now

      wqueue.emit!(:expressions, :update, :expression => self)

      nil
    end

    # Asks expstorage[s] to unstore persisted version of self.
    #
    # Will require the error journal as well to remove the error for
    # this expression if any.
    #
    def unpersist

      wqueue.emit!(:expressions, :delete, :fei => @fei)
      wqueue.emit!(:errors, :remove, { :fei => @fei }) if @has_error
    end

    # Only called in case of emergency (when the scheduler persistent data
    # got lost).
    #
    # See Ruote::Scheduler#reload
    #
    def reschedule_timeout

      return unless @timeout_at

      @timeout_job_id = scheduler.at(@timeout_at, @fei, :cancel).job_id

      persist
        # have to save the new @timeout_job_id
    end

    protected

    # A tag is a named pointer to an expression (name => fei).
    # It's stored in a variable.
    #
    def consider_tag

      if @tagname = attribute(:tag)

        set_variable(@tagname, @fei)
        wqueue.emit(:expressions, :entered_tag, :tag => @tagname, :fei => @fei)
      end
    end

    # If the expressions has a :timeout attribute, will schedule a cancel
    # after the given period of time.
    #
    # TODO : timeout at
    #
    def consider_timeout

      if timeout = attribute(:timeout)

        j = scheduler.in(timeout, @fei, :cancel)

        @timeout_at = j.at
        @timeout_job_id = j.job_id
      end
    end

    # Applies a given child (given by its index in the child list)
    #
    # Note that by default, this persists the parent expression.
    #
    def apply_child (child_index, workitem, forget=false)

      pool.apply_child(self, child_index, workitem, forget)
    end

    # Replies to the parent expression.
    #
    # This method contains lots of logic.
    #
    def reply_to_parent (workitem)

      if @tagname
        unset_variable(@tagname)
        wqueue.emit(:expressions, :left_tag, :tag => @tagname, :fei => @fei)
      end

      if @timeout_job_id
        scheduler.unschedule(@timeout_job_id)
      end

      if @state == :failing # @on_error is implicit (#fail got called)

        trigger_on_error(workitem)

      elsif (@state == :cancelling) and @on_cancel
        # @state == :dying doesn't trigger @on_cancel

        trigger_on_cancel(workitem)

      elsif (@state == :timing_out) and @on_timeout

        trigger_on_timeout(workitem)

      else

        if @updated_tree && @parent_id

          # updates the tree of the parent expression with the changes
          # made to the tree in this expression

          pexp = parent
            # making sure to call #parent 1! especially in no cache envs

          pexp.update_tree
          pexp.updated_tree[2][@fei.child_id] = @updated_tree
          pexp.persist
        end

        pool.reply_to_parent(self, workitem)
      end
    end

    # Shared by the trigger_on_ methods. No external use.
    #
    def apply_tree (tree, opts)

      pool.send(:apply, opts.merge(
        :tree => tree,
        :fei => @fei,
        :parent_id => @parent_id,
        :workitem => @applied_workitem,
        :variables => @variables))
    end

    # if any on_cancel handler is present, will trigger it.
    #
    def trigger_on_cancel (workitem)

      apply_tree(
        @on_cancel.is_a?(String) ? [ @on_cancel, {}, [] ] : @on_cancel,
        :on_cancel => true)
    end

    # Triggers the :on_error handler attached to this expression.
    #
    def trigger_on_error (workitem)

      handler = @on_error.to_s

      if handler == 'undo' # which got just done (cancel)

        pool.reply_to_parent(self, workitem)

      else # handle

        apply_tree(
          handler == 'redo' ? tree : [ handler, {}, [] ],
          :on_error => true)
      end
    end

    # Triggers the :on_timeout handler attached to this expression.
    #
    def trigger_on_timeout (workitem)

      handler = @on_timeout.to_s

      if handler == 'error'

        # building and emitting an 'artifical' error

        message = [ :expressions, :apply, {
          :tree => tree,
          :fei => @fei,
          :workitem => @applied_workitem,
          :variables => @variables } ]

        wqueue.emit(
          :errors,
          :s_expression_pool, # somehow...
          { :error => TimeoutError.new(attribute(:timeout)),
            :wfid => @fei.wfid, # parent wfid ?
            :message => message })

      else

        apply_tree(
          handler == 'redo' ? tree : [ handler, {}, [] ],
          :on_timeout => true)
      end
    end
  end
end

