#--
# Copyright (c) 2005-2012, John Mettraux, jmettraux@gmail.com
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
  # 're-opening' the FlowExpression class to add methods like set_vf and co.
  #
  class FlowExpression

    protected

    def set_v(key, value, unset=false)

      if unset
        unset_variable(key)
      else
        set_variable(key, value)
      end
    end

    def set_f(key, value, unset=false)

      if unset
        h.applied_workitem['fields'].delete(key) # why not Ruote.unset() ?
      else
        Ruote.set(h.applied_workitem['fields'], key, value)
      end
    end

    PREFIX_REGEX = /^([^:]+):(.+)$/
    F_PREFIX_REGEX = /^f/

    def set_vf(key, value, unset=false)

      field, key = if m = PREFIX_REGEX.match(key)
        [ F_PREFIX_REGEX.match(m[1]), m[2] ]
      else
        [ true, key ]
      end

      field ? set_f(key, value, unset) : set_v(key, value, unset)
    end
  end
end

