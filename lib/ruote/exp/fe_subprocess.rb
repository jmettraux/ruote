#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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

require 'ruote/exp/flowexpression'


module Ruote::Exp

  #
  # An expression for invoking a subprocess.
  #
  #   pdef = Ruote.process_definition do
  #     sequence do
  #       subprocess :ref => 'delivering'
  #       subprocess 'invoicing'
  #       refill_stock :if => '${v:stock_size} < 10'
  #     end
  #     define 'delivering' do
  #       # ...
  #     end
  #     define 'invoicing' do
  #       # ...
  #     end
  #     define 'refill_stock' do
  #       # ...
  #     end
  #   end
  #
  class SubprocessExpression < FlowExpression

    names :subprocess


    def apply

      ref = attribute(:ref) || attribute_text

      raise "no subprocess referred in #{tree}" unless ref

      pos, tree = lookup_variable(ref)

      raise "no subprocess named '#{ref}' found" unless tree.is_a?(Array)

      pool.launch_sub(pos, tree, self, @applied_workitem)
    end
  end
end

