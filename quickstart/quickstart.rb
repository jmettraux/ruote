
require 'rufus-json/automatic'
require 'ruote'
require 'ruote/storage/fs_storage'

#
# preparing the engine

# The ruote onion:
# * storage at the core
# * a worker tied to the storage
# * a dashboard with all the levers as the outer layer
#
# This storage uses the filesystem to persist all the ruote messages, workitems,
# etc...

ruote = Ruote::Dashboard.new(
  Ruote::Worker.new(
    Ruote::FsStorage.new('ruote_work')))

#
# registering participants

# Registering two block participants. Real-world participant usually come as
# classes, not blocks.

ruote.register_participant :alpha do |workitem|
  workitem.fields['message'] = { 'text' => 'hello !', 'author' => 'Alice' }
end

ruote.register_participant :bravo do |workitem|
  puts
  puts "I received a message from #{workitem.fields['message']['author']}"
end

#
# defining a process

pdef = Ruote.process_definition :name => 'test' do
  participant :alpha
  participant :bravo
end

#
# launching, creating a process instance

wfid = ruote.launch(pdef)

ruote.wait_for(wfid)
  # blocks current thread until our process instance terminates

# => 'I received a message from Alice'

