#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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


module Ruote

  class ParticipantExpression < FlowExpression

    #include FilterMixin
    #include TimeoutMixin
    #include ConditionMixin
      # TODO

    names :participant

    attr_accessor :applied_workitem

    def apply (workitem)

      @participant_name = @attributes[:ref]

      participant = pmap.lookup(@participant_name)

      raise(
        ArgumentError.new(
          "pexp : no participant named #{@participant_name.inspect}")
      ) unless participant

      @applied_workitem = workitem.dup

      store_self

      wqueue.emit(
        :participants, :dispatch,
        :participant => participant, :workitem => workitem)
    end

    #def reply (workitem)
    #end

    def cancel

      return unless @applied_workitem

      wqueue.emit(
        :participants, :cancel,
        :participant => pmap.lookup(@participant_name), :fei => workitem)
    end
  end
end

