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

  # Turning a tree into a numbered string view
  #
  #   require 'ruote/util/tree'
  #   require 'ruote/reader/ruby_dsl'
  #
  #   pdef = Ruote.process_definition :name => 'def0' do
  #     sequence do
  #       alpha
  #       bravo
  #     end
  #   end
  #
  #   p pdef
  #     # => ["define", {"name"=>"def0"}, [
  #     #      ["sequence", {}, [
  #     #        ["alpha", {}, []],
  #     #        ["bravo", {}, []]]]]]
  #
  #   puts Ruote.tree_to_s(pdef)
  #     # =>
  #     #    0  define {"name"=>"def0"}
  #     #      0_0  sequence {}
  #     #        0_0_0  alpha {}
  #     #        0_0_1  bravo {}
  #
  def self.tree_to_s(tree, expid='0')

    d = expid.split('_').size - 1
    s = "#{' ' * d * 2}#{expid}  #{tree[0]} #{tree[1].inspect}\n"
    tree[2].each_with_index { |t, i| s << tree_to_s(t, "#{expid}_#{i}") }
    s
  end

  # Compacts
  #
  #   [ 'participant', { 'ref' => 'sam' }, [] ] # and
  #   [ 'subprocess', { 'ref' => 'compute_prime' }, [] ]
  #
  # into
  #
  #   [ 'sam', {}, [] ] # and
  #   [ 'compute_prime', {}, [] ]
  #
  # to simplify tree comparisons.
  #
  def self.compact_tree(tree)

    tree = tree.dup

    if %w[ participant subprocess ].include?(tree[0])

      ref =
        tree[1].delete('ref') ||
        begin
          kv = tree[1].find { |k, v| v == nil }
          tree[1].delete(kv[0])
          kv[0]
        end

      tree[0] = ref

    else

      tree[2] = tree[2].collect { |t| compact_tree(t) }
    end

    tree
  end

  # Used by some projects, used to be called from Ruote::ProcessStatus.
  #
  # Given a tree
  #
  #   [ 'define', { 'name' => 'nada' }, [
  #     [ 'sequence', {}, [ [ 'alpha', {}, [] ], [ 'bravo', {}, [] ] ] ]
  #   ] ]
  #
  # will output something like
  #
  #   { '0' => [ 'define', { 'name' => 'nada' } ],
  #     '0_0' => [ 'sequence', {} ],
  #     '0_0_0' => [ 'alpha', {} ],
  #     '0_0_1' => [ 'bravo', {} ] },
  #
  # An initial offset can be specifid with the 'pos' argument.
  #
  # Don't touch 'h', it's an accumulator.
  #
  def self.decompose_tree(t, pos='0', h={})

    h[pos] = t[0, 2]
    t[2].each_with_index { |c, i| decompose_tree(c, "#{pos}_#{i}", h) }
    h
  end

  # Used by some projects, used to be called from Ruote::ProcessStatus.
  #
  # Given a decomposed tree like
  #
  #   { '0' => [ 'define', { 'name' => 'nada' } ],
  #     '0_0' => [ 'sequence', {} ],
  #     '0_0_0' => [ 'alpha', {} ],
  #     '0_0_1' => [ 'bravo', {} ] },
  #
  # will recompose it to
  #
  #   [ 'define', { 'name' => 'nada' }, [
  #     [ 'sequence', {}, [ [ 'alpha', {}, [] ], [ 'bravo', {}, [] ] ] ]
  #   ] ]
  #
  # A starting point in the recomposition can be given with the 'pos' argument.
  #
  def self.recompose_tree(h, pos='0')

    t = h[pos]

    return nil unless t

    t << []
    i = 0

    loop do
      tt = recompose_tree(h, "#{pos}_#{i}")
      break unless tt
      t.last << tt
      i = i + 1
    end

    t
  end
end

