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

  class HashWrapper

    DELEGATED = %w[ delete size length [] []= ]

    def initialize(h)

      @h = h
    end

    def to_h

      @h
    end

    def method_missing(m, *args)

      k = m.to_s

      return @h.send(k, *args) if DELEGATED.include?(k)

      if k[-1, 1] == '=' && args.size == 1
        @h[k[0..-2]] = args.first
      elsif args.size == 0
        @h[k]
      end
    end
  end

  module WithH

#    def h=(hash)
#
#      @h = hash
#      @hw = nil
#    end

    def h

      @hw ||= HashWrapper.new(@h)
    end

    def to_h

      @h
    end

    def self.included(target)

      def target.h_reader(*names)

        names.each do |name|

          define_method(name) { @h[name.to_s] }
        end
      end

      def target.h_accessor(*names)

        names.each do |name|

          define_method(name) { @h[name.to_s] }
          define_method("#{name}=") { |val| @h[name.to_s] = val }
        end
      end
    end
  end
end

