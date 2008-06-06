
#
# a little script that traces the flow given as input
#

require 'rubygems'

require 'openwfe/expressions/raw_prog'
require 'openwfe/tools/flowtracer'

class MyProcessDefinition < OpenWFE::ProcessDefinition
  def make
    process_definition :name => "mpd", :revision => "0" do
      sequence do
        participant "alpha"
        set :field => "toto", :value => "toto value"
        participant "bravo"
      end
    end
  end
end

OpenWFE::trace_flow(MyProcessDefinition)

