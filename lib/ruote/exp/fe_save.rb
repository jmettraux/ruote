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
  # Saves the current workitem fields into a variable or into a field.
  #
  #   save :to_field => 'old_workitem'
  #     # or
  #   save :to => 'f:old_workitem'
  #     #
  #     # saves a copy of the fields of the current workitem into itself,
  #     # in the field named 'old_workitem'
  #
  #   save :to_variable => '/wix'
  #     # or
  #   save :to => 'v:/wix'
  #     #
  #     # saves a copy of the current workitem in the varialbe 'wix' at
  #     # the root of the process
  #
  # See also the 'restore' expression (Ruote::Exp::RestoreExpression).
  #
  class SaveExpression < FlowExpression

    names :save

    def apply

      to_v, to_f = determine_tos

      if to_v
        set_variable(to_v, h.applied_workitem['fields'])
      elsif to_f
        set_f(to_f, Ruote.fulldup(h.applied_workitem['fields']))
      #else
        # do nothing
      end

      reply_to_parent(h.applied_workitem)
    end

    def reply(workitem)

      # empty, never called
    end
  end
end

