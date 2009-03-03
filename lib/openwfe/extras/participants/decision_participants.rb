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
  #   class TestDefinition0 < ProcessDefinition
  #     sequence do
  #       set :field => "weather", :value => "cloudy"
  #       set :field => "month", :value => "may"
  #       decision
  #       _print "${f:take_umbrella?}"
  #     end
  #   end
  #
  #
  #   csvParticipant = CsvParticipant.new(
  #   """
  #   in:weather, in:month, out:take_umbrella?
  #   ,,
  #   raining,  ,     yes
  #   sunny,    ,     no
  #   cloudy,   june,   yes
  #   cloudy,   may,    yes
  #   cloudy,   ,     no
  #   """)
  #
  #   engine.register_participant("decision", csvParticipant)
  #
  #   # ...
  #
  #   engine.launch(new OpenWFE::LaunchItem(TestDefinition0)
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

