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
  # Cancels a whole process instance.
  #
  #   pdef = Ruote.process_definition :name => 'test' do
  #     sequence do
  #       participant :ref => 'editor'
  #       concurrence do
  #         participant :ref => 'reviewer1'
  #         participant :ref => 'reviewer2'
  #         sequence do
  #           participant :ref => 'main_reviewer'
  #           cancel_process :if => '${f:over} == true'
  #         end
  #       end
  #       participant :ref => 'editor'
  #     end
  #   end
  #
  # This example has a 'main_reviewer' with the ability to cancel the whole
  # process, if he sets the workitem field 'over' to 'true'.
  #
  # If the goal is to cancel only a segment of a process instance, the
  # expression 'undo' (Ruote::Exp::UndoExpression) is better suited.
  #
  # == 'terminate'
  #
  # Sometimes 'terminate' reads better than 'cancel_process'
  #
  #   Ruote.process_definition do
  #     alice :task => 'do this'
  #     terminate :if => '${no_need_for_bob}'
  #     bob :task => 'do that'
  #     charly :task => 'just do it'
  #   end
  #
  class CancelProcessExpression < FlowExpression

    names :cancel_process, :terminate, :kill_process

    def apply

      @context.storage.put_msg(
        'cancel_process',
        'wfid' => h.fei['wfid'],
        'flavour' => name == 'kill_process' ? 'kill' : nil)
    end

    def reply(workitem)

      # never called
    end
  end
end

