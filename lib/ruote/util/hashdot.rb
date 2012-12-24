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


module Ruote

  module HashDot

    def method_missing(m, *args)

      m = m.to_s

      if m[-1, 1] == '='
        if args.first.nil?
          self.delete(m[0..-2]); nil
        else
          self[m[0..-2]] = args.first
        end
      else
        self[m]
      end
    end

    def dump

      s = "~~ h ~~\n"
      each do |k, v|
        s << "  * '#{k}' => "
        s << v.inspect
        s << "\n"
      end
      s << "~~ . ~~"
    end

    #--
    # Useful when debugging some 'stack too deep' issue
    #
    #def self.included(target)
    #  raise target.to_s unless target.to_s.match(/\bHash\b/)
    #end
    #++
  end

  module WithH

    def self.included(target)

      def target.h_reader(*names)
        names.each do |name|
          define_method(name) do
            @h[name.to_s]
          end
        end
      end
    end
  end
end

