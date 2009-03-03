#--
# Copyright (c) 2008-2009, John Mettraux, jmettraux@gmail.com
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
# Made in Japan (as opposed to "swiss made).
#++


module OpenWFE

  #
  # A container for the from_json() method
  #
  module Json

    def self.from_json (text)

      return JSON.parse(text) \
        if defined?(JSON)

      # WARNING : ActiveSupport is quite permissive...

      return ActiveSupport::JSON.decode(text) \
        if defined?(ActiveSupport::JSON)

      nil
    end

    #
    # Makes sure the input is turned into a hash
    #
    def self.as_h (h_or_json)

      h_or_json.is_a?(Hash) ? h_or_json : from_json(h_or_json)
    end

    protected

    def is_valid_json? (s)
    end
  end
end

