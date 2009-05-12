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

    def launch (tree, workitem)

      apply(tree, new_fei, nil, workitem)
    end

    def apply (tree, fei, parent_id, workitem)

      # TODO : participant and subprocess lookup

      exp_class = expmap.exp_class(tree.first)
      exp = exp_class.new(fei, parent_id, tree)

      expstorage[fei] = exp

      exp.context = @context

      workitem.fei = fei

      #exp.apply(workitem)
      workqueue.queue(exp, :apply, workitem)
    end

    #def reapply (fei)
    #end

    def apply_child (exp, child_index, workitem)

      fei = exp.fei.new_child_fei(child_index)

      apply(exp.children[child_index], fei, exp.fei, workitem)
    end

    def reply_to_parent (exp, workitem)

      expstorage.delete(exp.fei)
      workitem.fei = exp.fei

      if exp.parent_id

        parent = expstorage[exp.parent_id]

        #parent.reply(workitem)
        workqueue.queue(parent, :reply, workitem)

      else

        puts "process #{exp.fei.wfid} over"
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
