#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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
    attr_reader :type # :re_apply or :update

    def initialize(fei, tree, type)

      @fei = fei
      @tree = tree
      @type = type
    end

    def to_s

      s = []
      s << self.class.name
      s << "  at:      #{@fei.sid} (#{@fei.expid})"
      s << "  action:  #{@type.inspect}"
      s << "  tree:"

      s.concat(
        Ruote::Reader.to_radial(@tree).split("\n").map { |l| "    | #{l}" })

      s.join("\n")
    end

    def apply(dboard, option=nil)

      option ||= @type
      option = option.to_sym

      return if option != :force_update && option != @type

      type = option == :force_update ? :update : @type

      if type == :re_apply
        dboard.re_apply(@fei, :tree => @tree)
      else
        dboard.update_expression(@fei, :tree => @tree)
      end
    end
  end

  #
  # A set of mutation points.
  #
  # Initialized by Ruote::Dashboard#compute_mutation
  #
  class Mutation

    # ProcessStatus instance (advanced stuff).
    #
    attr_reader :ps

    attr_reader :points

    def initialize(dboard, wfid, tree)

      @dboard = dboard
      @points = []
      @ps = @dboard.ps(wfid)

      walk(@ps.root_expression, Ruote.compact_tree(tree))

      @points = @points.sort_by { |point| point.fei.expid }
    end

    def to_a

      @points.collect { |pt|
        { 'fei' => pt.fei, 'action' => pt.type, 'tree' => pt.tree }
      }
    end

    def to_s

      @points.collect(&:to_s).join("\n")
    end

    # Applies the mutation, :update points first then :re_apply points.
    #
    # Accepts an option, nil means apply all, :update means apply only
    # update mutations points, :re_apply means apply on re_apply points,
    # :force_update means apply all but turn re_apply points into update
    # points.
    #
    def apply(option=nil)

      updates, re_applies = @points.partition { |pt| pt.type == :update }
      points = updates + re_applies

      points.each { |pt| pt.apply(@dboard, option) }

      self
    end

    protected

    def register(point)

      pt = @points.find { |p| p.fei == point.fei }

      if pt && point.type == :re_apply
        @points.delete(pt)
        @points << point
      else
        @points << point
      end
    end

    # Look for mutation points in an expression and its children.
    #
    def walk(fexp, tree)

      ftree = Ruote.compact_tree(@ps.current_tree(fexp))

      if ftree[0] != tree[0] || ftree[1] != tree[1]
        #
        # if there is anything different between the current tree and the
        # desired tree, let's force a re-apply

        register(MutationPoint.new(fexp.fei, tree, :re_apply))

      elsif ftree[2] == tree[2]
        #
        # else, if the tree children are the same, exit, there is nothing to do

        return

      else

        register(MutationPoint.new(fexp.fei, tree, :update))
          #
          # NOTE: maybe a switch for this mutation not to be added would
          #       be necessary...

        if fexp.is_concurrent?
          #
          # concurrent expressions follow a different heuristic

          walk_concurrence(fexp, ftree, tree)

        else
          #
          # all other expressions are considered sequence-like

          walk_sequence(fexp, ftree, tree)
        end
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

        register(MutationPoint.new(fexp.fei, tree, :re_apply))

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

          register(MutationPoint.new(fexp.fei, tree, :re_apply))
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
        register(MutationPoint.new(fexp.fei, tree, :re_apply))
        return
      end

      if ecurrent != current
        #
        # if the child currently applied is supposed to change, let's walk
        # it down
        #
        walk(@ps.fexp(fexp.children.first), current)
      end

      #if etail != tail
      #  #
      #  # if elements are added at the end of the sequence, let's register
      #  # a mutation that simply changes the tree (no need to re-apply)
      #  #
      #  register(MutationPoint.new(fexp.fei, tree, :update))
      #end
    end
  end
end

