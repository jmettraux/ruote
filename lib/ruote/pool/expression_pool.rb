#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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
require 'ruote/engine/context'
require 'ruote/queue/subscriber'


module Ruote

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

    def reply (workitem)

      wqueue.emit(
        :expressions, :reply,
        :expression => expstorage[workitem.fei], :workitem => workitem)
    end

    #def cancel (fei)
    #  wqueue.emit(:expressions, :cancel, :fei => fei)
    #end
    #def reapply (fei)
    #end

    def apply_child (exp, child_index, workitem)

      fei = exp.fei.new_child_fei(child_index)

      apply(exp.tree.last[child_index], fei, exp.fei, workitem, nil)
    end

    def reply_to_parent (exp, workitem)

      wqueue.emit(:expressions, :delete, :fei => exp.fei)
      workitem.fei = exp.fei

      if exp.parent_id

        parent = expstorage[exp.parent_id]

        wqueue.emit(
          :expressions, :reply,
          :expression => parent, :workitem => workitem)

      else

        wqueue.emit(
          :processes, :terminated,
          :wfid => exp.fei.wfid, :workitem => workitem)
      end
    end

    protected

    def receive (eclass, emsg, eargs)

      if eclass == :expressions

        apply_reply_exp(emsg, eargs) if emsg == :apply || emsg == :reply

      elsif eclass == :processes

        launch(eargs) if emsg == :launch

      end
    end

    def apply_reply_exp (emsg, eargs)

      begin

        eargs[:expression].send(emsg, eargs[:workitem])

      rescue Exception => e

        # TODO : implement on_error

        wqueue.emit(
          :errors,
          :s_expression_pool,
          {
            :error => e,
            :message => [ :expressions, emsg, eargs ]
          })
      end
    end

    def apply (tree, fei, parent_id, workitem, variables)

      # TODO : participant and subprocess lookup

      exp_class = expmap.expression_class(tree.first)

      raise "unknown expression '#{tree.first}'" if not exp_class

      exp = exp_class.new(fei, parent_id, tree, variables)

      wqueue.emit(:expressions, :update, :expression => exp)

      exp.context = @context

      workitem.fei = fei

      wqueue.emit(
        :expressions, :apply,
        :expression => exp, :workitem => workitem)

      fei
    end

    def launch (args)

      fei = new_fei(args[:wfid])

      apply(args[:tree], fei, nil, args[:workitem], {})
        # {} variables are set here
    end

    def new_fei (wfid)

      fei = FlowExpressionId.new
      fei.engine_id = engine.engine_id
      fei.wfid = wfid || wfidgen.generate
      fei.expid = '0'

      fei
    end
  end
end
