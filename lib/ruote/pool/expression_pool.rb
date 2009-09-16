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

require 'ruote/fei'
require 'ruote/exp/raw'
require 'ruote/engine/context'
require 'ruote/queue/subscriber'


module Ruote

  #
  # A kind of hub for expression activity (apply/reply and launch + cancel).
  #
  class ExpressionPool

    include EngineContext
    include Subscriber

    # Making sure to observe the work queue once the context is known
    #
    def context= (c)

      @context = c
      subscribe(:expressions)
      subscribe(:processes)
    end

    # Workitem coming back from outside [the engine].
    #
    def reply (workitem, fei=nil)

      wqueue.emit(
        :expressions, :reply,
        :workitem => workitem, :fei => fei || workitem.fei)
    end

    # Cancels an expression (and its expression children)
    #
    # If kill is set to true, no on_cancel handler will be considered, the
    # expression and its tree will get killed.
    #
    def cancel_expression (fei, flavour)

      wqueue.emit(:expressions, :cancel, :fei => fei, :flavour => flavour)
    end

    # Immediately 'forgets' the expression (if still present).
    # This sets the expression's @parent_id to nil
    #
    # Returns true if the expression was found and forgotten.
    #
    def forget_expression (fei)

      if exp = expstorage[fei]
        exp.forget
        true
      else
        false
      end
    end

    # This method is called by expressions when applying one of the child
    # expressions.
    #
    def apply_child (exp, child_index, workitem, forget)

      fei = exp.fei.new_child_fei(child_index)

      exp.register_child(fei) unless forget

      wqueue.emit(
        :expressions, :apply,
        :tree => exp.tree.last[child_index],
        :fei => fei,
        :parent_id => forget ? nil : exp.fei,
        :workitem => workitem,
        :variables => forget ? exp.compile_variables : nil)
    end

    # Called by expressions when replying to their parent expression.
    #
    def reply_to_parent (exp, workitem)

      exp.unpersist

      workitem.fei = exp.fei

      if exp.parent_id

        wqueue.emit(
          :expressions, :reply,
          :fei => exp.parent_id, :workitem => workitem)

      else

        msg = case exp.state
        when :cancelling then :cancelled
        when :dying then :killed
        else :terminated
        end

        wqueue.emit(
          :processes, msg, :wfid => exp.fei.wfid, :workitem => workitem)
      end
    end

    # Called by the subprocess expression when launching a subprocess instance.
    #
    def launch_sub (pos, tree, parent, workitem, opts={})

      i = parent.fei.dup
      i.wfid = "#{i.parent_wfid}_#{get_next_sub_id(parent)}"
      i.expid = pos

      forget = opts[:forget]

      parent.register_child(i) unless forget

      wqueue.emit(:processes, :launch_sub, :fei => i)

      variables = (
        forget ? parent.compile_variables : {}
      ).merge(opts[:variables] || {})

      wqueue.emit(
        :expressions, :apply,
        :tree => tree,
        :fei => i,
        :parent_id => forget ? nil : parent.fei,
        :workitem => workitem,
        :variables => variables)
    end

    # Re-applies the given expression.
    #
    # If cancel is set to true, will cancel then re-apply.
    #
    def re_apply (fei, cancel)

      exp = expstorage[fei]

      return unless exp

      if cancel

        # wire exp's tree to itself on_cancel and cancel

        exp.on_cancel = exp.tree
        exp.persist
        cancel_expression(exp.fei, nil) # flavour is nil, regular cancel

      else

        apply(
          :tree => exp.tree,
          :fei => exp.fei,
          :parent_id => exp.parent_id,
          :workitem => exp.applied_workitem,
          :variables => exp.variables)
      end
    end

    protected

    # Applying a branch (creating an expression for it and applying it).
    #
    def apply (eargs)

      tree = eargs[:tree]
      fei = eargs[:fei]
      parent_id = eargs[:parent_id]
      workitem = eargs[:workitem]
      variables = eargs[:variables]

      # NOTE : orphaning will copy vars so parent == nil is OK.

      exp_name = tree.first
      exp_class = expmap.expression_class(exp_name)

      # expressions have priority over participants and subprocesses

      if not exp_class

        k, v = temp_exp(
          parent_id, variables, workitem, tree
        ).iterative_var_lookup(exp_name)

        sub = v
        part = plist.lookup(k)

        sub = k if (not sub) && (not part) && Ruote.is_uri?(k)
          # for when a variable points to the URI of a[n external] subprocess

        if sub or part

          # don't bother passing the looked up value

          tree_opts = tree[1].merge('ref' => k)
          tree_opts.merge!('original_ref' => exp_name) if k != exp_name

          tree = [ part ? 'participant' : 'subprocess', tree_opts, tree[2] ]

          exp_name = tree.first
        end

        exp_class = expmap.expression_class(exp_name)
      end

      raise "unknown expression '#{exp_name}'" if not exp_class

      workitem.fei = fei

      exp = exp_class.new(@context, fei, parent_id, tree, variables, workitem)
      exp.persist

      wqueue.emit(:expressions, :apply, :fei => exp.fei)

      # instantiating, persisting and then triggering the apply
      #
      # it's a bit indirect, but necessary in case of error (to allow for
      # error replaying)

      fei
    end

    # Returns a temporary expression, complete with #lookup_variable and
    # #lookup_on.
    # For internal use only.
    #
    def temp_exp (parent_id, variables, workitem, tree=[ 'nada', {}, [] ])

      Ruote::Exp::FlowExpression.new(
        @context, nil, parent_id, tree, variables, workitem)
    end

    # Returns the next available sub id for the given expression.
    #
    def get_next_sub_id (parent)

      prefix, last_sub_id = parent.lookup_variable('/__next_sub_id__')

      prefix ||= ''
      last_sub_id ||= -1

      last_sub_id = last_sub_id + 1

      parent.set_variable('/__next_sub_id__', [ prefix, last_sub_id ])

      "#{prefix}#{last_sub_id}"
    end

    EXP_MESSAGES = %w[ apply reply cancel ].collect { |m| m.to_sym }
    PROCESS_MESSAGES = %w[ launch cancel kill ].collect { |m| m.to_sym }

    # Reacting upon :expressions and :processes events.
    #
    def receive (eclass, emsg, eargs)

      if eclass == :expressions

        expressions_receive(emsg, eargs) if EXP_MESSAGES.include?(emsg)

      elsif eclass == :processes

        self.send(emsg, emsg, eargs) if PROCESS_MESSAGES.include?(emsg)

      end
    end

    def extract_info (emsg, eargs)

      wi = eargs[:workitem]
      fei = eargs[:fei] || wi.fei
      exp = expstorage[fei]

      [ wi, fei, exp ]
    end

    # Calling apply/reply/cancel on an expression (called by #receive).
    #
    def expressions_receive (emsg, eargs)

      wi, fei, exp = extract_info(emsg, eargs)

      begin

        return apply(eargs) if emsg == :apply && eargs[:tree]

        return unless exp
          # can't reply to a missing expression...

        case emsg
          when :apply then exp.do_apply
          when :reply then exp.do_reply(wi)
          when :cancel then exp.do_cancel(eargs[:flavour])
        end

      rescue Exception => e

        #puts
        #p e
        #e.backtrace.each { |l| puts l }
        #puts

        ex = if exp
          exp
        else
          Ruote::Exp::RawExpression.new(
            @context, fei, eargs[:parent_id], eargs[:tree], wi)
        end
        ex.persist
          #
          # making sure there is at least 1 expression in the storage
          # so that engine#process yields something

        handle_exception(emsg, eargs, e)
      end
    end

    def handle_exception (emsg, eargs, exception)

      wi, fei, exp = extract_info(emsg, eargs)

      (emsg != :cancel) && handle_on_error(exp) && return
        # return if error got handled

      exp.instance_variable_set(:@state, :failed)
      exp.persist

      efei = exp ? exp.fei : fei

      wqueue.emit(
        :errors,
        :s_expression_pool,
        { :error => exception,
          :wfid => efei.wfid,
          :parent_wfid => efei.parent_wfid,
          :message => [ :expressions, emsg, eargs ] })
    end

    # Handling errors during apply/reply of expressions.
    #
    def handle_on_error (fexp)

      return false if fexp.state == :failing

      oe_exp = fexp.lookup_on(:error)

      return false unless oe_exp

      handler = oe_exp.on_error.to_s

      wqueue.emit(
        :processes, :on_error, :fei => oe_exp.fei, :handler => handler)
        # just a notification

      return false if handler == ''

      oe_exp.fail

      true # error was handled here.

    rescue Exception => e

      puts
      puts "== rescuing error handling"
      puts
      p [ fexp.class, fexp.fei ]
      puts
      p e
      puts e.backtrace
      puts

      # simply let fail for now

      # TODO : maybe emit some kind of message

      false
    end

    # Launches a new process instance.
    # (triggered by received a [ :processes, :launch, ... ] event)
    #
    def launch (emsg, eargs)

      fei = new_fei(eargs[:wfid])

      tree = eargs[:tree]
      vars = {}

      if expmap.is_definition?(tree)
        name, tree = Ruote::Exp::DefineExpression.reorganize(expmap, tree)
        vars[name] = [ '0', tree ] if name
      end

      wqueue.emit(
        :expressions, :apply,
        :tree => tree,
        :fei => fei,
        :workitem => eargs[:workitem],
        :variables => vars)
    end

    # Cancels a process instance.
    # (triggered by received a [ :processes, :cancel|:kill, ... ] event)
    #
    # If the message is :kill (instead of :cancel), a 'kill' is performed.
    # It's like a cancel, but no on_cancel handler is considered.
    #
    def cancel (emsg, eargs)

      root_fei = new_fei(eargs[:wfid])

      cancel_expression(root_fei, emsg == :kill ? :kill : nil)
    end
    alias :kill :cancel

    # Generates a new FlowExpressionId instance (used when lauching a new
    # process instance).
    #
    def new_fei (wfid)

      fei = FlowExpressionId.new
      fei.engine_id = engine.engine_id
      fei.wfid = wfid || wfidgen.generate
      fei.expid = '0'

      fei
    end
  end
end
