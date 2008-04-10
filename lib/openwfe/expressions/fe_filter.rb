#
#--
# Copyright (c) 2007, John Mettraux, OpenWFE.org
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
# $Id: definitions.rb 2725 2006-06-02 13:26:32Z jmettraux $
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

require 'openwfe/expressions/filter'


module OpenWFE

    #
    # This expression applies a filter to the workitem used by the process
    # segment nested within it.
    #
    #     class TestFilter48a0 < ProcessDefinition
    #         sequence do
    #
    #             set :field => "readable", :value => "bible"
    #             set :field => "writable", :value => "sand"
    #             set :field => "randw", :value => "notebook"
    #             set :field => "hidden", :value => "playboy"
    #
    #             alice
    #
    #             filter :name => "filter0" do
    #                 sequence do
    #                     bob
    #                     charly
    #                 end
    #             end
    #
    #             doug
    #         end
    #
    #         filter_definition :name => "filter0" do
    #             field :regex => "readable", :permissions => "r"
    #             field :regex => "writable", :permissions => "w"
    #             field :regex => "randw", :permissions => "rw"
    #             field :regex => "hidden", :permissions => ""
    #         end
    #     end
    #
    # In this example, the filter 'filter0' is applied upon entering bob and
    # charly's sequence.
    #
    # Please note that the filter will not be enforced between bob and charly,
    # it is enforced just before entering the sequence and just after leaving 
    # it.
    #
    # Note also that the ParticipantExpression accepts a 'filter' attribute,
    # thus :
    #
    #     <filter name="filter0">
    #         <participant ref="toto" />
    #     </filter>
    #
    # can be simplified to :
    #
    #     <participant ref="toto" filter="filter0" />
    #
    class FilterExpression < FlowExpression
        include FilterMixin

        names :filter

        attr_accessor :applied_workitem, :filter


        def apply workitem

            if @children.length < 1
                reply_to_parent workitem
                return
            end

            @applied_workitem = workitem.dup
            filter_in workitem, :name

            store_itself

            get_expression_pool.apply @children[0], workitem
        end

        def reply workitem

            filter_out workitem

            reply_to_parent workitem
        end
    end

end

