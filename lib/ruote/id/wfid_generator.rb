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


module Ruote

  class WfidGenerator

    def initialize (context)

      @context = context

      @last =
        @context.storage.get('variables', 'last_wfid') ||
        { 'type' => 'variables', '_id' => 'last_wfid', 'raw' => Time.now.utc.to_f }
    end

    def generate

      raw = get_raw

      "#{raw.strftime('%Y%m%d%H%M%S')}-#{raw.usec}"
    end

    protected

    def get_raw

      lraw = @last['raw'] + 0.01

      raw = Time.now.utc
      while raw.to_f <= lraw; raw = raw + 0.01; end

      @last['raw'] = raw.to_f

      last = @context.storage.put(@last)

      if last
        #
        # put failed, have to re-ask
        #
        @last = last
        get_raw
      else
        #
        # put successful, we can build a new wfid
        #
        raw
      end
    end
  end
end

