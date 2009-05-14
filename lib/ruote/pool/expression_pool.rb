#--
# Copyright (c) 2009, John Mettraux, jmettraux@gmail.com
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


module Ruote

  class ExpressionPool

    include EngineContext

    # Making sure to observe the work queue once the context is known
    #
    def context= (c)

      @context = c
      wqueue.add_observer(:expressions, self)
    end

    def launch (tree, workitem)

      apply(tree, new_fei, nil, workitem)
    end

    def apply (tree, fei, parent_id, workitem)

      # TODO : participant and subprocess lookup

      exp_class = expmap.expression_class(tree.first)

      raise "unknown expression '#{tree.first}'" if not exp_class

      exp = exp_class.new(fei, parent_id, tree)

      wqueue.emit(:expressions, :update, :expression => exp)

      exp.context = @context

      workitem.fei = fei

      wqueue.emit(
        :expressions, :apply,
        :expression => exp, :workitem => workitem)

      fei
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

      apply(exp.tree.last[child_index], fei, exp.fei, workitem)
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
          :processes, :terminate,
          :fei => exp.fei, :workitem => workitem)
      end
    end

    def receive (eclass, emsg, eargs)

      case emsg
      when :apply, :reply
        # TODO : add error interception here !
        eargs[:expression].send(emsg, eargs[:workitem])
      end
    end

    protected

    def new_fei

      fei = FlowExpressionId.new
      fei.engine_id = engine.engine_id
      fei.wfid = wfidgen.generate
      fei.expid = '0'

      fei
    end
  end
end
