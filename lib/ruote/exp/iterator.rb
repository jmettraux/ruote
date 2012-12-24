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
  # A Mixin shared by Ruote::IteratorExpression and
  # Ruote::ConcurrentIteratorExpression
  #
  module IteratorMixin

    protected

    def determine_list

      h.times_iterator = false

      #
      # :times or :branches

      if count = attribute(:times) || attribute(:branches)

        list = ((0...count.to_i).to_a rescue nil)

        if list
          h.times_iterator = true
          return list
        end
      end

      #
      # :on{_...}

      split_list(lookup_val_prefix('on'))
    end

    def split_list(list)

      if list.is_a?(String)

        sep = attribute(:separator) || attribute(:sep) || ','
        list.split(sep).collect { |e| e.strip }

      elsif list.respond_to?(:to_a)

        list.to_a

      elsif list.respond_to?(:[]) and list.respond_to?(:length)

        list

      else

        []
      end
    end
  end
end

