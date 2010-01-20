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

  module Condition

    SET_REGEX = /(\S*?)( +is)?( +not)?( +set)$/
    COMPARISON_REGEX = /(.*?) *(==|!=|>=|<=|>|<|=~) *(.*)/

    def self.apply? (sif, sunless)

      return (true?(sif)) if sif
      return ( ! true?(sunless)) if sunless

      true
    end

    # TODO : rconditional
    #        is it really necessary ? there is already ${r:xxx}

    def self.true? (conditional)

      conditional = unescape(conditional)

      if m = SET_REGEX.match(conditional)
        eval_is(m)
      elsif m = COMPARISON_REGEX.match(conditional)
        compare(m)
      else
        to_b(conditional)
      end
    end

    protected

    def self.eval_is (match)

      match = match[1..-2].select { |e| e != nil }

      negative = match.find { |m| m == ' not' }

      first = match.first.strip
      is_set = first != '' && first != 'is'

      negative ? (not is_set) : is_set
    end

    def self.unescape (s)

      s ? s.to_s.gsub('&amp;', '&').gsub('&gt;', '>').gsub('&lt;', '<') : nil
    end

    def self.to_b (o)

      o = o.strip if o.is_a?(String)

      not(o == nil || o == false || o == 'false' || o == '')
    end

    def self.compare (m)

      return (m[1].=~(Regexp.new(m[3])) != nil) if m[2] == '=~'

      a = narrow_to_f(m[1])
      b = narrow_to_f(m[3])

      if a.class != b.class
        a = m[1]
        b = m[3]
      end

      #a.send(m[2], b)
        # ruby 1.8.x doesn't like that one

      a = strip(a)
      b = strip(b)

      m[2] == '!=' ? ( ! a.send('==', b)) : a.send(m[2], b)
    end

    def self.narrow_to_f (s)

      Float(s) rescue s
    end

    def self.strip (s)

      s.respond_to?(:strip) ? s.strip : s
    end
  end
end

