#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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
  # TODO
  #
  class RegisterpExpression < FlowExpression

    names :registerp

    def apply

      registerp_allowed?

      if pa = attribute('participant')

        register_participant(h.applied_workitem['fields'][pa])

      elsif pas = attribute('participants')

        h.applied_workitem['fields'][pas].each do |pa|
          register_participant(pa)
        end

      else

        register_participant(attributes)
      end

      reply_to_parent(h.applied_workitem)
    end

    def reply (workitem)

      # never called
    end

    protected

    def registerp_allowed?

      raise ArgumentError.new(
        "'registerp_allowed' is set to false, cannot [un]register " +
        "participants from process definitions"
      ) if context['registerp_allowed'] != true
    end

    def register_participant (info)

      name, (klass, opts) = Ruote::ParticipantEntry.read(info)

      context.engine.register_participant(name, klass, opts)
    end
  end

  #
  # TODO
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

