#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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


require 'openwfe/utils'


module OpenWFE

  #
  # Gathering methods for mixing (merging) workitems.
  #
  module MergeMixin

    #
    # Merges a source workitem into a target workitem (the fields
    # of the source will overwrite the fields in the target).
    #
    # Returns the resulting (merged) workitem.
    #
    def merge_workitems (wi_target, wi_source, override=false)

      return wi_source unless wi_target
      return wi_target unless wi_source

      return wi_source if override

      wi_source.attributes.each do |k, v|

        nk = OpenWFE.fulldup(k)
        nv = OpenWFE.fulldup(v)

        wi_target.attributes[nk] = nv
      end

      wi_target
    end
  end

end

