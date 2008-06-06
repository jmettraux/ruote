
#
# This is the code used in the blog post :
# http://jmettraux.wordpress.com/2007/12/03/state-machine/
#


# some setup

require 'openwfe/def'
require 'openwfe/engine'
require 'openwfe/participants'

engine = OpenWFE::Engine.new

alice = engine.register_participant(
  :alice, OpenWFE::HashParticipant)
bob = engine.register_participant(
  :bob, OpenWFE::HashParticipant)

class MyDefinition < OpenWFE::ProcessDefinition
  sequence do
    alice
    bob
  end
end

# later ...

#fei = engine.launch MyDefinition
#
#sleep 0.050
#  # it's asynchronous, so...
#
#puts "alice holds #{alice.size} workitem(s)"
#puts "bob   holds #{bob.size} workitem(s)"
#
#puts engine.process_status(fei)


class My2ndDefinition < OpenWFE::ProcessDefinition
  sequence do
    at :state => "redaction"
    alice
    at :state => "correction"
    bob
    alice
    at :state => "approval"
    charly
  end

  process_definition :name => "at" do
    set :var => "/state", :val => "${state}"
  end
end

#fei = engine.launch My2ndDefinition
#
#sleep 0.050
#
#puts "state : " + engine.lookup_variable(
#  'state', fei.workflow_instance_id)

class My3rdDefinition < OpenWFE::ProcessDefinition
  sequence do
    alice :tag => "redaction"
    sequence :tag => "correction" do
      bob
      alice
    end
    charly :tag => "approval"
  end
end

fei = engine.launch My3rdDefinition

sleep 0.050

puts "state : " + engine.process_status(
  fei.workflow_instance_id).tags.inspect

