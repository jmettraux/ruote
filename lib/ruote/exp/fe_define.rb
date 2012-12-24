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


module Ruote::Exp

  #
  # The main names for this expression are 'define' and 'process_definition'.
  # It simply encloses a process definition (and gives it a name and revision
  # if needed).
  #
  #   pdef = Ruote.process_definition :name => 'test', :revision => '0' do
  #     sequence do
  #       participant :ref => 'alice'
  #       participant :ref => 'bob'
  #     end
  #   end
  #
  # It's used for subprocess definitions as well.
  #
  #   pdef = Ruote.process_definition :name => 'test', :revision => '0' do
  #     sequence do
  #       buy_food
  #       cook_food
  #     end
  #     define 'buy_food' do
  #       participant :ref => 'alice'
  #     end
  #     define :name => 'cook_food' do
  #       participant :ref => 'bob'
  #     end
  #   end
  #
  # == like a sequence
  #
  # Ruote 2.0 treats the child expressions of a 'define' expression like a
  # 'sequence' expression does. Thus, this
  #
  #   pdef = Ruote.process_definition :name => 'test' do
  #     sequence do
  #       buy_food
  #       cook_food
  #     end
  #   end
  #
  # is equivalent to
  #
  #   pdef = Ruote.process_definition :name => 'test' do
  #     buy_food
  #     cook_food
  #   end
  #
  class DefineExpression < FlowExpression

    names :define, :process_definition, :workflow_definition

    def apply

      t = self.class.reorganize(tree).last

      name = attribute(:name) || attribute_text

      set_variable(name, [ h.fei['expid'], t ]) if name
        #
        # fei.expid : keeping track of the expid/branch for the subprocess
        #             (so that graphical representations match)

      reply_to_parent(h.applied_workitem)
    end

    # Returns true if the tree's root expression is a definition
    # (define, process_definition, ...)
    #
    def self.is_definition?(tree)

      self.expression_names.include?(tree.first)
    end

    # Used by instances of this class and also the expression pool,
    # when launching a new process instance.
    #
    def self.reorganize(tree)

      definitions, bodies = tree[2].partition { |b| is_definition?(b) }
      name = tree[1]['name'] || tree[1].keys.find { |k| tree[1][k] == nil }

      definitions = definitions.collect { |d| reorganize(d)[1] }

      [ name, [ 'define', tree[1], definitions + bodies ] ]
    end
  end
end

