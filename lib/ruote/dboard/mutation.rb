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
  # Gathers info about a possible mutation. The point of application (fei),
  # the new tree (tree) and if it's a re_apply or an update (only changing
  # the tree of the expression behind (fei)).
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
  # A set of mutation points.
  #
  # Initialized by Ruote::Dashboard#compute_mutation
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

    # Look for mutation points in an expression and its children.
    #
    def walk(fexp, tree)

      ftree = Ruote.compact_tree(@ps.current_tree(fexp))

      if ftree[0] != tree[0] || ftree[1] != tree[1]
        #
        # if there is anything different between the current tree and the
        # desired tree, let's force a re-apply

        @points << MutationPoint.new(fexp.fei, tree, true)

      elsif ftree[2] == tree[2]
        #
        # else, if the tree children are the same, exit, there is nothing to do

        return

      elsif fexp.is_concurrent?
        #
        # concurrent expressions follow a different heuristic

        walk_concurrence(fexp, ftree, tree)

      else
        #
        # all other expressions are considered sequence-like

        walk_sequence(fexp, ftree, tree)

      end
    end

    # Look for mutation points in a concurrent expression (concurrence or
    # concurrent-iterator).
    #
    def walk_concurrence(fexp, ftree, tree)

      if ftree[2].size != tree[2].size
        #
        # that's lazy, but why not?
        #
        # we could add/apply a new child...

        @points << MutationPoint.new(fexp.fei, tree, true)

      else
        #
        # if there is a least one child that replied and whose
        # tree must be changes, then re-apply the whole concurrence
        #
        # else try to re-apply only the necessary branch (walk them)

        branches = ftree[2].zip(tree[2]).each_with_object([]) { |(ft, t), a|
          #
          # match child expressions (if not yet replied) with current tree (ft)
          # and desired tree (t)
          #
          cfei = fexp.children[a.size]
          cexp = cfei ? @ps.fexp(cfei) : nil
          a << [ cexp, ft, t ]
          #
        }.select { |cexp, ft, t|
          #
          # only keep diverging branches
          #
          ft != t
        }

        branches.each do |cexp, ft, t|

          next if cexp

          # there is at least one branch that replied,
          # this forces re-apply for the whole concurrence

          @points << MutationPoint.new(fexp.fei, tree, true)
          return
        end

        branches.each do |cexp, ft, t|
          #
          # we're left with divering branches that haven't yet replied,
          # let's walk to register the mutation point deep into it

          walk(cexp, t)
        end
      end
    end

    # Look for mutation points in any non-concurrent expression.
    #
    def walk_sequence(fexp, ftree, tree)

      i = fexp.child_ids.first

      ehead = ftree[2].take(i)
      ecurrent = ftree[2][i]
      etail = ftree[2].drop(i + 1)
      head = tree[2].take(i)
      current = tree[2][i]
      tail = tree[2].drop(i + 1)

      if ehead != head
        #
        # if the name and/or attributes of the exp are supposed to change
        # then we have to reapply it
        #
        @points << MutationPoint.new(fexp.fei, tree, true)
        return
      end

      if ecurrent != current
        #
        # if the child currently applied is supposed to change, let's walk
        # it down
        #
        walk(@ps.fexp(fexp.children.first), current)
      end

      if etail != tail
        #
        # if elements are added at the end of the sequence, let's register
        # a mutation that simply changes the tree (no need to re-apply)
        #
        @points << MutationPoint.new(fexp.fei, tree, false)
      end
    end
  end
end

