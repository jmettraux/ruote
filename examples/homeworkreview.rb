
### EXAMPLE IN PREPARATION ###

#
# an OpenWFEru example
#

require 'rubygems'

require 'openwfe/engine/engine'
require 'openwfe/expressions/raw_prog'
#require 'openwfe/participants/soapparticipants'
#require 'openwfe/participants/atomparticipants'


#
# the process definition
#
# instead of using the classical OpenWFE XML process definitions, we
# define the flow as a Ruby class

class ReviewFlow < OpenWFE::ProcessDefinition
  def make
    process_definition :name => "homework_review", :revision => "0.1" do
      sequence do
      end
    end
  end
end

#
# the engine
#
# a simple in memory engine, no persistence whatsoever for now.

engine = OpenWFE::Engine.new

#
# The Participants
#
# Ideally participants are shared by more than one process definition
# (a person is usually part of more than one business process in
# his organization)

# a small debug participant, as you can see, a participant can
# directly be a ruby block (which receives the workitem)
# (it's commented out at the end of the flow)
#
engine.register_participant("puts_workitem") do |workitem|
  puts
  puts workitem.to_s
  puts
end

#
# launching

launchitem = LaunchItem.new(QuoteLookupFlow)
  #
  # Passing the process definition class as the unique
  # LaunchItem parameter

launchitem.symbols = "aapl, sunw, msft, lnux"
  #
  # directly setting the value for the field "symbols"

engine.launch(launchitem)

