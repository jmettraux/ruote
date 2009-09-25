
$:.unshift('lib') # running from ruote/ probably

require 'rubygems'
require 'ruote/engine'

# preparing the engine

engine = Ruote::FsPersistedEngine.new

# registering participants

engine.register_participant :alpha do |workitem|
  workitem.fields['message'] = { 'text' => 'hello !', 'author' => 'Alice' }
end

engine.register_participant :bravo do |workitem|
  puts "I received a message from #{workitem.fields['message']['author']}"
end

# defining a process

pdef = Ruote.process_definition :name => 'test' do
  sequence do
    participant :alpha
    participant :bravo
  end
end

# launching, creating a process instance

wfid = engine.launch(pdef)

sleep 1

# => 'I received a message from Alice'
