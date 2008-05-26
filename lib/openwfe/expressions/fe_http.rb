#
#--
# Copyright (c) 2008, John Mettraux, OpenWFE.org
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

require 'rufus/verbs'
require 'openwfe/expressions/flowexpression'


module OpenWFE

    #
    # The HTTP verbs as OpenWFEru (Ruote) expressions.
    #
    # Useful for basic RESTful BPM.
    #
    # This expression uses the rufus-verbs gem and accepts the exact
    # sames parameters (attributes) as this gem.
    #
    # see http://rufus.rubyforge.org/rufus-verbs
    #
    # some examples (in a ruby process definition) :
    #
    #     sequence do
    #
    #         get "http://server.example.com/res0.xml"
    #             # stores the XML content in the field 'rbody'
    #     end
    #
    class HttpExpression < FlowExpression

        names :hpost, :hget, :hput, :hdelete


        def apply (workitem)

            verb = @fei.expression_name[1..-1]

            uri =
                lookup_attribute(:uri, workitem) ||
                fetch_text_content(workitem)

            data = workitem.attributes['hdata']
            opts = workitem.attributes['hoptions'] || {}

            params = lookup_attributes workitem
            params = params.merge opts

            params = params.inject({}) { |r, (k, v)| r[k.intern] = v; r }
                # 'symbolize' keys

            params[:uri] = uri
            params[:data] = data if data

            # do it

            Thread.new do
                #
                # move execution out of process engine main thread
                # else would block other processes execution

                begin

                    res = Rufus::Verbs.send verb, params

                    workitem.rcode = res.code
                    workitem.rheaders = res.to_hash
                    workitem.rbody = res.body

                #rescue Timeout::Error => te
                #
                #    workitem.rerror = te.to_s
                #    workitem.rcode = -1

                rescue Exception => e

                    linfo { "apply() failed : #{e.to_s}" }

                    workitem.rerror = e.to_s
                    workitem.rcode = -1
                end

                # over

                reply_to_parent workitem
            end
        end

        #def reply (workitem)
        #end

        #def cancel
        #   # kill thread ...
        #   nil
        #end

    end

end

