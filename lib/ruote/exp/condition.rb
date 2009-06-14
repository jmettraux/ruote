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


module Ruote

  #
  # Adding the skip? method to some expressions (like participant, subprocess,
  # and so on)
  #
  module ConditionMixin

    def skip? (attname=:if, nattname=:unless)

      positive = eval_cond(attname)
      return true if positive == false

      negative = eval_cond(nattname)
      return false if negative == true

      false
    end

    protected

    def eval_cond (attname)

      conditional = attribute(attname)
      rconditional = attribute("r#{attname}")

      conditional = unescape(conditional)
      rconditional = unescape(rconditional)

      return ruby_eval(rconditional) if rconditional and not conditional
      return nil if not conditional

      r = eval_is_set(conditional)
      return (not r) if r != nil

      begin
        return to_b(ruby_eval(conditional))
      rescue Exception => e
      end

      to_b(ruby_eval(do_quote(conditional)))
    end

    def unescape (s)

      s ? s.to_s.gsub('&amp;', '&').gsub('&gt;', '>').gsub('&lt;', '<') : nil
    end

    def ruby_eval (s)

      # TODO : treechecker !

      eval(s)
    end

    SET_REGEX = /(\S*?)( +is)?( +not)?( +set)$/

    def eval_is_set (s)

      m = SET_REGEX.match(s)

      return nil unless m

      val = m[1]
      val = val.strip if val

      n = m[-2]
      n = n.strip if n

      val = (val != '')
      n = (n == 'not')

      n ? (not val) : val
    end

    def to_b (o)

      o = o.strip if o.is_a?(String)
      not (o == nil || o == false || o == 'false' || o == '')
    end
  end
end

