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


module Ruote

  class SaveExpression < FlowExpression

    names :save

    def apply

      tk =
        has_attribute(*%w[ v var variable ].map { |k| "to_#{k}" }) ||
        has_attribute(*%w[ f fld field ].map { |k| "to_#{k}" })

      return reply_to_parent(@applied_workitem) unless tk

      key = attribute(tk)

      if tk.match(/^to_v/)

        set_variable(key, @applied_workitem.dup)

      elsif tk.match(/^to_f/)

        @applied_workitem.attributes[key] =
          Ruote.fulldup(@applied_workitem.attributes)
      end

      reply_to_parent(@applied_workitem)
    end

    def reply (workitem)
      # empty, never called
    end
  end
end

