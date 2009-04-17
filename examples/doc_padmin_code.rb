
require 'rubygems'
require 'openwfe/engine/fs_engine'
require 'openwfe/participants'


engine = OpenWFE::FsPersistedEngine.new(
  :definition_in_launchitem_allowed => true)

engine.reload
  # resyncronizes engine with previously persisted process instances

orders01 = OpenWFE.process_definition :name => 'orders', :revision => '0.1' do
  sequence do
    warehouse
    accounting
    customer
  end
end

orders02 = OpenWFE.process_definition :name => 'orders', :revision => '0.2' do
  sequence do
    concurrence do
      warehouse
      accounting
    end
    customer
  end
end

engine.register_participant :warehouse, OpenWFE::YamlParticipant
engine.register_participant :accounting, OpenWFE::YamlParticipant
engine.register_participant :customer, OpenWFE::YamlParticipant
  #
  # super dumb participants

engine.launch(orders01)
engine.launch(orders01)
engine.launch(orders02)

sleep 0.350
# ...

processes = engine.processes

puts "wfid\t\t\twfname\trev\terrors\tpaused"
puts '-' * 54

processes.each do |ps|
  wfid = ps.wfid
  puts "#{ps.wfid}\t#{ps.wfname}\t#{ps.wfrevision}\t#{ps.errors.size}\t#{ps.paused}"
end

