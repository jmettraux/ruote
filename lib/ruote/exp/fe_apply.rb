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
  # The 'apply' expression is an advanced expression.
  #
  # It takes as input an AST and applies it. The AST may be placed in a field
  # or a variable or passed directly to the apply.
  #
  # These apply examples :
  #
  #   apply :tree => [ 'echo', { 'nada' => nil }, [] ]
  #
  #   sequence do
  #     set :var => 'tree', :val => [ 'echo', { 'nada' => nil }, [] ]
  #     apply # looks by default in variable 'tree'
  #   end
  #
  #   sequence do
  #     set :var => 't', :val => [ 'echo', { 'nada' => nil }, [] ]
  #     apply :tree_var => 't'
  #   end
  #
  #   sequence do
  #     set :field => 't', :val => [ 'echo', { 'nada' => nil }, [] ]
  #     apply :tree_field => 't'
  #   end
  #
  # All are equivalent to
  #
  #   echo 'nada'
  #
  #
  # == apply and subprocesses
  #
  # There is an interesting way of using 'apply', it's close to the way of
  # the Ruby "yield" expression.
  #
  #   pdef = Ruote.process_definition 'test' do
  #     sequence do
  #       handle do
  #         participant 'alpha'
  #       end
  #       handle do
  #         participant 'bravo'
  #       end
  #     end
  #     define 'handle' do
  #       sequence do
  #         participant 'prepare_data'
  #         apply
  #         participant 'rearrange_data'
  #       end
  #     end
  #   end
  #
  # With this process definition, the particpant alpha and bravo are handed
  # a workitem in sequence, but each time, the data gets prepared and
  # re-arranged.
  #
  # 'apply' simply picks the value of the tree to apply in the local variable
  # 'tree'.
  #
  # Passing variables to applied trees is possible :
  #
  #   pdef = Ruote.process_definition do
  #     handle do
  #       participant '${v:target}', :message => 'x'
  #     end
  #     define 'handle' do
  #       sequence do
  #         participant 'prepare_data'
  #         apply :v => 'alpha'
  #         apply :v => 'bravo'
  #         participant 'rearrange_data'
  #       end
  #     end
  #   end
  #
  #
  # == on_error
  #
  # It's OK, to place an on_error on the apply
  #
  #   pdef = Ruote.process_definition do
  #     handle do
  #       sequence do
  #         echo 'in'
  #         nemo
  #       end
  #     end
  #     define 'handle' do
  #       apply :on_error => 'notify' # <==
  #       echo 'over.'
  #     end
  #     define 'notify' do
  #       echo 'error'
  #     end
  #   end
  #
  class ApplyExpression < FlowExpression

    names :apply

    # TODO : maybe accept directly ruby and xml (and json)
    # TODO : _yield ?

    # TODO : apply [ 'echo', { 'nada' => nil }, [] ]

    def apply

      #
      # find 'tree'

      tree =
        lookup_val_prefix('tree', :escape => true) ||
        lookup_variable('tree')

      return reply_to_parent(h.applied_workitem) unless tree

      #
      # apply 'tree'

      launch_sub(
        "#{h.fei['expid']}_0", tree,
        :variables => compile_atts(:escape => true))
    end
  end
end

