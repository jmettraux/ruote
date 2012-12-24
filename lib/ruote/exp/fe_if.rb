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
  # The 'if' construct found in many programming languages.
  #
  # == _if ?
  #
  # Why the "_if" in all the examples below? Well, all the examples are using
  # the Ruby DSL, using 'if' alone isn't possible, the Ruby parser would think
  # it's the Ruby's own if...
  #
  # But process definitions written in Radial
  # (see http://jmettraux.github.com/2012-09-03-ruote-2.3.0.html) don't have
  # this restriction:
  #
  #   if '${customer} == fred'
  #     salesman_henry  # then clause
  #     salesman_josh   # else clause
  #
  # == then / else clauses
  #
  # The 'if' expression accepts two or three children branches, in pseudo-code
  # it looks like:
  #
  #   _if do
  #     <condition>
  #     <then clause>
  #   end
  #
  #   # or
  #
  #   _if <condition> do
  #     <then clause>
  #   end
  #
  #   # or
  #
  #   _if do
  #     <condition>
  #     <then clause>
  #     <else clause>
  #   end
  #
  #   # or
  #
  #   _if <condition> do
  #     <then clause>
  #     <else clause>
  #   end
  #
  # This piece of process definition:
  #
  #   _if '${customer} == fred' do
  #     salesman_henry
  #     salesman_josh
  #   end
  #
  # is thus interpreted as:
  #
  #   _if '${customer} == fred' do
  #     salesman_henry  # then clause
  #     salesman_josh   # else clause
  #   end
  #
  # If the intent was to express a sequence henry - josh, it should be
  # written as:
  #
  #   _if '${customer} == fred' do
  #     sequence do # then clause
  #       salesman_henry
  #       salesman_josh
  #     end
  #   end
  #
  # Note this can be alternatively written as:
  #
  #   sequence :if => '${customer} == fred' do
  #     salesman_henry
  #     salesman_josh
  #   end
  #
  # == examples
  #
  # Here are some examples:
  #
  #   _if do
  #     equals :field_value => 'customer', :other_value => 'British Petroleum'
  #     participant :ref => 'Allister'
  #   end
  #
  # and:
  #
  #   _if :test => '${f:customer} == British Petroleum' do
  #     participant :ref => 'Allister'
  #   end
  #
  # An else clause is accepted:
  #
  #   _if do
  #     equals :field_value => 'customer', :other_value => 'British Petroleum'
  #     participant :ref => 'Allister'
  #     participant :ref => 'Bernardo'
  #   end
  #
  # or:
  #
  #   _if :test => '${f:customer} == British Petroleum' do
  #     participant :ref => 'Allister'
  #     participant :ref => 'Bernardo'
  #   end
  #
  # Note that any expression accepts an :if attribute:
  #
  #   participant :ref => 'Al', :if => '${f:customer} == British Petroleum'
  #
  #
  # == shorter
  #
  # The :test can be shortened to a :t :
  #
  #   _if :t => '${f:customer.name} == Fred' do
  #     subprocess 'premium_course'
  #     subprocess 'regular_course'
  #   end
  #
  # When using Ruby to generate the process definition tree, you can simply do:
  #
  #   _if '${f:customer.name} == Fred' do
  #     subprocess 'premium_course'
  #     subprocess 'regular_course'
  #   end
  #
  class IfExpression < FlowExpression

    names :if

    def apply

      reply(h.applied_workitem)
    end

    # called by 'else', 'then' or perhaps 'equals'
    #
    def reply(workitem)

      if workitem['fei'] == h.fei # apply --> reply

        h.test = attribute(:test)
        h.test = attribute(:t) if h.test.nil?
        h.test = attribute_text if h.test.nil?
        h.test = nil if h.test == ''

        offset = (h.test.nil? || Condition.true?(h.test)) ? 0 : 1

        apply_child(offset, workitem)

      else # reply from a child

        if h.test != nil || Ruote::FlowExpressionId.child_id(workitem['fei']) != 0

          reply_to_parent(workitem)

        else

          apply_child(workitem['fields']['__result__'] == true ? 1 : 2, workitem)
        end
      end
    end

    protected

    def apply_child(index, workitem)

      if tree_children[index]
        super
      else
        reply_to_parent(workitem)
      end
    end
  end
end

