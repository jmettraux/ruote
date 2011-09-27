
$:.unshift('lib') # running from ruote/ probably

require 'rubygems'

begin
  require 'yajl'
rescue LoadError => le
  require 'json'
end

require 'ruote'
require 'ruote/storage/fs_storage'


# preparing the engine

dashboard = Ruote::Dashboard.new(
  Ruote::Worker.new(
    Ruote::FsStorage.new(
      'ruote_work',
      's_logger' => [ 'ruote/log/test_logger', 'Ruote::TestLogger' ])))


# registering participants

dashboard.register_participant :alpha do |workitem|
  workitem.fields['message'] = { 'text' => 'hello !', 'author' => 'Alice' }
end

dashboard.register_participant :bravo do |workitem|
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

wfid = dashboard.launch(pdef)

dashboard.wait_for(wfid)
  # blocks current thread until our process instance terminates

# => 'I received a message from Alice'

