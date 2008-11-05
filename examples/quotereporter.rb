
#
# an OpenWFEru example
#

require 'rubygems'

require 'openwfe/engine/engine'
require 'openwfe/participants/soapparticipants'
require 'openwfe/extras/participants/atomfeed_participants'


#
# the process definition
#
# instead of using the classical OpenWFE XML process definitions, we
# define the flow as a Ruby class

class QuoteLookupFlow < OpenWFE::ProcessDefinition
 sequence do

   #
   # lookup quotes

   iterator :on_field_value => "symbols", :to_field => "symbol" do
     sequence do

       set :field => "quote_${f:__ip__}_name", :field_value => "symbol"

       participant :quote_service

       set :field => "quote_${f:__ip__}_value", :field_value => "__result__"
     end
   end

   #
   # update feed

   set :field => "atom_entry_title" do
     "quote feed at ${r:Time.now}"
   end
     #
     # wrapping some ruby code for eval at runtime
     # with ${r: ruby code ... }

   participant :feed

   #participant :ref => "puts_workitem"
   #participant :ref => :puts_workitem
   #participant "puts_workitem"
   #participant :puts_workitem
   puts_workitem
     #
     # the five notations are equivalent
 end
end

#
# the engine
#
# a simple in memory engine, no persistence whatsoever for now.

engine = OpenWFE::Engine.new({ :definition_in_launchitem_allowed  => true })

#
# The Participants
#
# Ideally participants are shared by more than one process definition
# (a person is usually part of more than one business process in
# his organization)

# the participant that looks up the quote values
#
quote_service = OpenWFE::SoapParticipant.new(
  "http://services.xmethods.net/soap",    # service URI
  "urn:xmethods-delayed-quotes",        # namespace
  "getQuote",                 # operation name
  [ "symbol" ])                 # param arrays (workitem fields)

engine.register_participant("quote_service", quote_service)

# the feed : at most 10 feed entries are kept.
#
# The entry template is specified as a block returning the template
# (a string containing xhtml).
#
# The feed is outputted in the current working directory ./atom_feed.xml
#
feed = OpenWFE::Extras::AtomFeedParticipant.new(10) do
  | flow_expression, participant, workitem |

  #
  # the template (xhtml by default) is generated via a block

  s = "<h3>quotes</h3>"

  s << "<ul>"

  workitem.__ic__.times do |i|
    #
    # within an iteration, the count of iterations is stored in the
    # workitem field "__ic__"
    #
    s << "<li>"
    s << workitem.attributes["quote_#{i}_name"].to_s
    s << " : "
    s << workitem.attributes["quote_#{i}_value"].to_s
    s << "</li>\n"
  end

  s << "</ul>"
end
engine.register_participant("feed", feed)

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
# launching (not lunching)

launchitem = OpenWFE::LaunchItem.new(QuoteLookupFlow)
  #
  # Passing the process definition class as the unique
  # LaunchItem parameter

launchitem.symbols = "aapl, sunw, msft, lnux"
  #
  # directly setting the value for the field "symbols"

engine.launch(launchitem)

# in this example, the engine is used once with only one process definition,
# but an OpenWFE engine is made to run multiple different process instances.

# as an extension example, to produce a feed for the next ten hours you would :
#
# 10.times do
#   engine.launch(launchitem)
#   sleep (3600) # one hour
# end

engine.join

