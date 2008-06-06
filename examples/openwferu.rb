
require 'rubygems'
require 'openwfe/def'
require 'openwfe/workitem'
require 'openwfe/engine/engine'

#
# instantiating an engine

ac = { :definition_in_launchitem_allowed => true }

engine = OpenWFE::Engine.new ac

#
# adding some participants

engine.register_participant :alice do |workitem|
  puts "alice got a workitem..."
  workitem.alice_comment = "this thing looks interesting"
end

engine.register_participant :bob do |workitem|
  puts "bob got a workitem..."
  workitem.bob_comment = "not for me, I prefer VB"
  workitem.bob_comment2 = "Bob rules"
end

engine.register_participant :summarize do |workitem|
  puts
  puts "summary of process #{workitem.fei.workflow_instance_id}"
  workitem.attributes.each do |k, v|
  next unless k.match ".*_comment$"
  puts " - #{k} : '#{v}'"
  end
end

#
# a process definition

class TheProcessDefinition0 < OpenWFE::ProcessDefinition
  sequence do
  concurrence do
    participant :alice
    participant :bob
  end
  participant :summarize
  end
end

#
# launching the process

li = OpenWFE::LaunchItem.new TheProcessDefinition0

li.initial_comment = "please give your impressions about http://ruby-lang.org"

fei = engine.launch(li)

engine.wait_for fei

