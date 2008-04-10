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

#require 'rubygems'
require 'rufus/decision' # gem 'rufus-decision'

require 'openwfe/utils'
require 'openwfe/util/dollar'
require 'openwfe/participants/participant'


module OpenWFE
module Extras

    #
    # Using CSV files to transform workitems
    # This concept is called "decision participant" in OpenWFEja, here
    # it's simply called "csv participant".
    #
    # See CsvTable for an explanation of the core concept behind a
    # CsvParticipant
    #
    # An example :
    #     
    #     class TestDefinition0 < ProcessDefinition
    #         sequence do
    #             set :field => "weather", :value => "cloudy"
    #             set :field => "month", :value => "may"
    #             decision
    #             _print "${f:take_umbrella?}"
    #         end
    #     end
    #     
    #     
    #     csvParticipant = CsvParticipant.new(
    #     """
    #     in:weather, in:month, out:take_umbrella?
    #     ,,
    #     raining,    ,         yes
    #     sunny,      ,         no
    #     cloudy,     june,     yes
    #     cloudy,     may,      yes
    #     cloudy,     ,         no
    #     """)
    #     
    #     engine.register_participant("decision", csvParticipant)
    #     
    #     # ...
    #     
    #     engine.launch(new OpenWFE::LaunchItem(TestDefinition0)
    #
    # Note that the CsvParticipant constructor also accepts a block.
    #
    class CsvParticipant
        include LocalParticipant

        attr_accessor :csv_table

        #
        # Builds a new CsvParticipant instance, csv_data or the block
        # may contain a File instance, a String or an Array of Array of 
        # String instances.
        #
        def initialize (csv_data=nil, &block)

            super()

            csv_data = block.call if block

            @csv_table = Rufus::DecisionTable.new csv_data
        end

        #
        # This is the method called by the engine (actually the 
        # ParticipantExpression) when handling a workitem to this participant.
        #
        def consume (workitem)

            fe = get_flow_expression workitem

            @csv_table.transform!(FlowDict.new(fe, workitem, 'f'))
                #
                # default_prefix set to 'f'

            reply_to_engine workitem
        end
    end

end
end

