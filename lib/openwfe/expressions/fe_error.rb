#--
# Copyright (c) 2008-2009, John Mettraux, jmettraux@gmail.com
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


module OpenWFE

  #
  # The 'error' expression provokes an error to occur in a process instance.
  # The error might then be treated by an error handler ('on_error' attribute)
  # or simply registered in the error journal and manually replayed.
  #
  #   sequence do
  #     participant :ref => 'unit1'
  #     error 'missing info', :if => "${f:customer} == ''"
  #     participant :ref => 'unit2'
  #   end
  #
  # In this hypothetical example, the error is triggered if the field customer
  # is empty.
  #
  # == replaying
  #
  # The error expression can be replayed without further ado (though it is
  # expected that the problem it raised attention to has be fixed). At replay
  # the expression will simply let the process instance resume.
  #
  # == on_error
  #
  # This expression can be used to let a process interrupt itself (replay case)
  # or to force the process into a 'fail path' (out of the 'happy path')
  #
  #   class MyDef0 < OpenWFE::ProcessDefinition
  #
  #     sequence :on_error => 'fail_path' do
  #
  #       participant :ref => 'unit1'
  #       error 'missing info', :if => "${f:customer} == ''"
  #       participant :ref => 'unit2'
  #     end
  #
  #     process_definition :name => 'fail_path' do
  #       # ... problem resolution subprocess ...
  #     end
  #   end
  #
  #
  class ErrorExpression < FlowExpression
    include ValueMixin
    include ConditionMixin

    #names :error, :exception
    names :error

    #
    # is set to true when the expression got applied once (and raised
    # its error).
    #
    attr_accessor :triggered


    def reply (workitem)

      return reply_to_parent(workitem) if @triggered
        #
        # when error is 'replayed' simply reply to parent to let flow resume

      conditional = eval_condition(:if, workitem, :unless)

      return reply_to_parent(workitem) if conditional == false

      text = workitem.get_result.to_s

      @triggered = true

      store_itself # making sure @triggered is saved

      raise(ForcedError.new(text))
    end
  end

end

