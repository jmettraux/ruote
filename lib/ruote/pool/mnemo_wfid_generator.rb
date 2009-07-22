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

require 'rufus/mnemo' # sudo gem install rufus-mnemo
require 'ruote/pool/wfid_generator'


module Ruote

  #
  # A rufus-mnemo based wfid generator.
  #
  class MnemoWfidGenerator < WfidGenerator

    include EngineContext

    SPLIT_REGEX = /-(.+)$/

    # Generates a wfid (workflow instance id (process instance id))
    #
    def generate

      @mutex.synchronize do

        wfid = Time.now
        wfid = @last + 0.001 if wfid <= @last

        @last = wfid
        save_last

        m = ((@last.to_f % 60 * 60 * 24) * 1000).to_i

        "#{@last.strftime('%Y%m%d')}-#{Rufus::Mnemo.from_integer(m)}"
      end
    end

    # Simply hands back the wfid string (this method is used by FsStorage
    # to determine in which dir expression should be stored).
    #
    def split (wfid)

      m = wfid.match(SPLIT_REGEX)

      Rufus::Mnemo.split(m[1]) rescue super(wfid)
    end
  end
end

