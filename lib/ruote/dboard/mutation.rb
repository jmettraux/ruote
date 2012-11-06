#--
# Copyright (c) 2005-2012, John Mettraux, jmettraux@gmail.com
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


module Ruote

  #
  # TODO
  #
  class MutationPoint

    attr_reader :fei
    attr_reader :tree
    attr_reader :re_apply # true or false

    def initialize(fei, tree, re_apply)

      @fei = fei
      @tree = tree
      @re_apply = re_apply
    end
  end

  #
  # TODO
  #
  class Mutation

    attr_reader :points

    def initialize(dboard, wfid, tree)

      @points = []
      @ps = dboard.ps(wfid)

      walk(@ps.root_expression, Ruote.compact_tree(tree))
    end

    def to_h

      @points.each_with_object({}) { |pt, h|
        h[pt.fei.h] = {
          'action' => pt.re_apply ? 're-apply' : 'update',
          'tree' => pt.tree
        }
      }
    end

    protected

    # TODO: fexp.tree != ps.current_tree(fexp) //!\\

    def walk(fexp, tree)

      ftree = Ruote.compact_tree(@ps.current_tree(fexp))

      if ftree[0] != tree[0] || ftree[1] != tree[1]

        @points << MutationPoint.new(fexp.fei, tree, true)

      elsif ftree[2] == tree[2]

        return

      elsif fexp.is_concurrent?

        walk_concurrence(fexp, ftree, tree)

      else

        walk_sequence(fexp, ftree, tree)

      end
    end

    def walk_concurrence(fexp, ftree, tree)

      if ftree[2].size != tree[2].size
        #
        # that's lazy, but why not?
        #
        # we could add/apply a new child...

        @points << MutationPoint.new(fexp.fei, tree, true)

      else

        # ???
      end
    end

    def walk_sequence(fexp, ftree, tree)

      i = fexp.child_ids.first

      ehead = ftree[2].take(i)
      ecurrent = ftree[2][i]
      etail = ftree[2].drop(i + 1)
      head = tree[2].take(i)
      current = tree[2][i]
      tail = tree[2].drop(i + 1)

      #puts ','
      #p ehead
      #p ecurrent
      #p etail
      #puts ','
      #p head
      #p current
      #p tail

      if ehead != head
        @points << MutationPoint.new(fexp.fei, tree, true)
        return
      end

      if ecurrent != current
        walk(@ps.fexp(fexp.children.first), current)
      end
      if etail != tail
        @points << MutationPoint.new(fexp.fei, tree, false)
      end
    end
  end
end

