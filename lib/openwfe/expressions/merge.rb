#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

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
    def merge_workitems (wiTarget, wiSource, override=false)

      return wiSource unless wiTarget
      return wiTarget unless wiSource

      return wiSource if override

      #puts "merge()"
      #puts "merge() source : " + wiSource.attributes.inspect
      #puts "merge() target : " + wiTarget.attributes.inspect

      wiSource.attributes.each do |k, v|

        #puts "merge() '#{k}' => '#{v}'"

        nk = OpenWFE::fulldup k
        nv = OpenWFE::fulldup v

        wiTarget.attributes[nk] = nv
      end

      #puts "merge() target after : " + wiTarget.attributes.inspect

      wiTarget
    end
  end

end

