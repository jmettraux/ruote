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

require 'ruote/exp/iterator'


module Ruote::Exp

  #
  # The 'add_branches'/'add_branch' expression can be used to add branches
  # to a concurrent-iterator while it is running.
  #
  #   concurrent_iterator :on => 'a, b, c' do
  #     sequence do
  #       participant :ref => 'worker_${v:i}'
  #       add_branches 'd, e', :if => '${v:/not_sufficient}'
  #     end
  #   end
  #
  # In this example, if the process level variable 'not_sufficient' is set to
  # true, workers d and e will be added to the iterated elements.
  #
  # 'add_branches' understand comma-separated list of values or direcltly
  # array of values, like the concurrent_iterator does. The :sep or :separator
  # attribute can be used for custom separators :
  #
  #   add_branches 'd|e|f', :sep => '|'
  #
  #
  # == :ref
  #
  # By default, add_branches looks up the first parent expression that is
  # concurrent_iterator. This is all well, but what when you have nested
  # concurrent_iterator and want to hit the enclosing one from inside the
  # enclosed one ? Or when you want to add branches from somewhere else
  # in the process instance, outside of the concurrent_iterator ?
  #
  #   concurrence do
  #
  #     concurrent_iterator :on => 'a, b, c', :tag => 'main' do
  #       subprocess :ref => 'perform_work'
  #     end
  #
  #     sequence do
  #       subprocess :ref => 'supervise_work'
  #       add_branches 'd, e', :ref => 'main', :if => '${f:more_cowbell}'
  #       rewind :if => '${f:more_cowbell}'
  #     end
  #   end
  #
  # The add_branches expression refers to the 'main' concurrent_iterator via
  # the :ref => 'main' attribute.
  #
  #
  # == missing concurrent_iterator
  #
  # If :ref points to nothing or add_branch has no :ref and is not placed
  # inside of a concurrent_iterator, the expression will silently have no
  # effect.
  #
  class AddBranchesExpression < FlowExpression

    include IteratorMixin

    names :add_branches, :add_branch

    def apply

      list = split_list(lookup_val_prefix('on') || attribute_text)
      it_fei = find_concurrent_iterator

      if list && it_fei

        wi = Ruote.fulldup(h.applied_workitem)
        wi['fields'][ConcurrentIteratorExpression::ADD_BRANCHES_FIELD] = list

        @context.storage.put_msg('reply', 'fei' => it_fei, 'workitem' => wi)
      end

      reply_to_parent(h.applied_workitem)
    end

    def reply(workitem)

      # never called
    end

    protected

    def find_concurrent_iterator

      #
      # ref ?

      if ref = attribute(:ref)

        return lookup_variable(ref)
      end

      #
      # no :ref, lookup first parent that is a concurrent_iterator

      exp = self.parent

      loop do

        break if exp.nil?
        break if exp.is_a?(ConcurrentIteratorExpression)

        exp = exp.parent
      end

      exp ? exp.h.fei : nil
    end
  end
end

