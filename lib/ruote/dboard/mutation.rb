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
      ps = dboard.ps(wfid)

      traverse(ps, ps.root_expression, tree)
    end

    def to_h

      @points.each_with_object({}) { |pt, h|
        h[pt.fei.sid] = {
          'action' => pt.re_apply ? 're-apply' : 'update',
          'tree' => pt.tree
        }
      }
    end

    protected

    def traverse(ps, fexp, tree)

      if fexp.tree[0] != tree[0] || fexp.tree[1] != tree[1]

        @points << MutationPoint.new(fexp.fei, tree, true)

      elsif fexp.tree[2] == tree[2]

        fexp.children.each_with_index do |cfei, i|
          traverse(ps, ps.fexp(cfei), tree[2][i])
        end

      #elsif fexp is a concurrence

      else # fexp is a sequence of some kind

        ft = fexp.tree[2]
        t = tree[2]
        i = fexp.child_ids.first + 1

        fleft = ft.take(i)
        fright = ft.drop(i)
        left = t.take(i)
        right = t.drop(i)

        @points << MutationPoint.new(fexp.fei, tree, fleft != left)
      end
    end
  end
end

