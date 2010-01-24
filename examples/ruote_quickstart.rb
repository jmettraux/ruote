
$:.unshift('lib') # running from ruote/ probably

require 'rubygems'
require 'ruote'
require 'ruote/storage/fs_storage'

# preparing the engine

engine = Ruote::Engine.new(
  Ruote::Worker.new(
    Ruote::FsStorage.new(
      'ruote_work',
      's_logger' => [ 'ruote/log/test_logger', 'Ruote::TestLogger' ])))

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

engine.wait_for(wfid)
  # blocks current thread until our process instance terminates

# => 'I received a message from Alice'

