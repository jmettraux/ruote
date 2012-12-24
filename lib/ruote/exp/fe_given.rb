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

require 'ruote/exp/fe_sequence'


module Ruote::Exp

  #
  # This expressions corresponds to a "case" statement in Ruby or a "switch"
  # in other languages.
  #
  # It accepts two variants "given that" and "given an x of".
  #
  # 'given' works in conjunction with the 'that' / 'of' expression.
  #
  #
  # == "given that"
  #
  #   given do
  #     that "${location} == paris" do
  #       subprocess "notify_and_wait_for_pickup"
  #     end
  #     that "${state} == ready" do
  #       subprocess "deliver"
  #     end
  #     # else...
  #     subprocess "do_something_else"
  #   end
  #
  #
  # == "given an x of"
  #
  #   given "${status}" do
  #     of "ordered" do
  #       participant "alpha"
  #     end
  #     of "delivered" do
  #       participant "alpha"
  #     end
  #     # else...
  #     subprocess "do_something_else"
  #   end
  #
  # This variant also accepts regular expressions :
  #
  #   given "${target}" do
  #     of "/-manager$/" do
  #       # ...
  #     end
  #     of /^user-/ do
  #       # ...
  #     end
  #   end
  #
  # == mixing 'that' and 'of'
  #
  # It's OK to use a "that" inside a "given an x" :
  #
  #   given '${target}' do
  #     that "${location} == paris" do
  #       subprocess "notify_and_wait_for_pickup"
  #     end
  #     of "home" do
  #       subprocess "return_procedure"
  #     end
  #   end
  #
  #
  # == the else part
  #
  # Anything that comes after the serie of 'that' and 'of' is considered in
  # the 'else' zone and is executed if none of the 'that' or 'of' triggered.
  #
  #   given '${target}' do
  #     that "${location} == paris" do
  #       subprocess "notify_and_wait_for_pickup"
  #     end
  #     of "home" do
  #       subprocess "return_procedure"
  #     end
  #     subprocess "do_this"
  #     subprocess "and_then_that"
  #   end
  #
  # Yes, two 'else' subprocesses will get executed one after the other (the
  # 'given' acting like a 'sequence' for them.
  #
  # Interestingly :
  #
  #   given '${target}' do
  #     of "home" do
  #       subprocess "return_procedure"
  #     end
  #     subprocess "do_this"
  #     of "office" do
  #       subprocess "go_to_work"
  #     end
  #     subprocess "and_then_that"
  #   end
  #
  # If the workitem field 'target' is set to 'home' only the 'return_procedure'
  # subprocess will get called.
  #
  # If the workitem field 'target' is set to 'office', the 'do_this'
  # subprocess, then the 'go_to_work' one will get called.
  #
  class GivenExpression < SequenceExpression

    names :given

    def reply(workitem)

      if given = attribute(:t) || attribute_text
        workitem['fields']['__given__'] = given
      end

      # as soon as one child says true, reply to the parent expression

      if workitem['fields']['__result__'].to_s == 'true'

        workitem['fields'].delete('__given__')
        workitem['fields'].delete('__result__')
        reply_to_parent(workitem)

      else

        super
      end
    end
  end
end

