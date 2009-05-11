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

require 'ruote/engine/context'


module Ruote

  class FlowExpression

    include EngineContext

    attr_accessor :fei
    attr_accessor :parent_id
    attr_accessor :children

    def initialize (fei, parent_id, children)

      @fei = fei
      @parent_id = parent_id
      @children = children
    end

    # The default implementation : replies to the parent expression
    #
    def reply (workitem)

      reply_to_parent(workitem)
    end

    protected

    def apply_child (child_index, workitem)

      expool.apply(@fei, child_index, workitem)
    end

    def store_self

      expool.store(self)
    end

    def reply_to_parent (workitem)

      expool.reply_to_parent(@fei, workitem)
    end
  end
end

