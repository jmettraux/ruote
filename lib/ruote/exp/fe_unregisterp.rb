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

require 'ruote/exp/fe_registerp'


module Ruote::Exp

  #
  # Unregisters a participant.
  #
  #   Ruote.process_definition do
  #     unregisterp 'alfred'
  #     unregisterp :name => 'bob'
  #   end
  #
  # Shows the same behaviour as
  #
  #   engine.unregister_participant 'alfred'
  #   engine.unregister_participant 'bob'
  #
  # The expression 'registerp' can be used to register participants from
  # a process definition.
  #
  class UnregisterpExpression < RegisterpExpression

    names :unregisterp

    def apply

      registerp_allowed?

      name = attribute(:name) || attribute_text

      result = begin
        context.engine.unregister_participant(name)
        true
      rescue
        false
      end

      h.applied_workitem['fields']['__result__'] = result

      reply_to_parent(h.applied_workitem)
    end
  end
end

