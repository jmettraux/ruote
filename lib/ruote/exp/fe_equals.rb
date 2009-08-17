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

  class EqualsExpression < FlowExpression

    names :equals

    def apply

      vals = grab_values

      @applied_workitem.result = if vals.size < 2
        false
      else
        vals.first == vals.last
      end

      reply_to_parent(@applied_workitem)
    end

    protected

    OTHER_REGEX = /^other\_(.+)$/

    def grab_values

      keys = attributes.keys.select { |k| ! COMMON_ATT_KEYS.include?(k) }

      keys.collect { |k| grab_value(k) }
    end

    def grab_value (k)

      attval = attribute(k)

      if m = OTHER_REGEX.match(k)
        k = m[1]
      end

      case k
      when /^f/ then @applied_workitem.attributes[attval]
      when /^var/ then lookup_variable(attval)
      when /^val/ then attval
      end
    end
  end
end

