
$:.unshift('lib')

require 'rubygems'
require 'ruote/engine'
require 'ruote/worker'
require 'ruote/part/storage_participant'
require 'ruote/storage/hash_storage'
require 'ruote/storage/fs_storage'

opts = {}

storage = if ARGV.include?('--fs')
  #FileUtils.rm_rf('work_mega') if ARGV.include?('-e')
  Ruote::FsStorage.new('work_mega', opts)
else
  Ruote::HashStorage.new(opts)
end

p storage.class

if ARGV.include?('-e')
  #
  # engine and worker
  #

  puts "... engine + worker ..."

  engine = Ruote::Engine.new(Ruote::Worker.new(storage))

  engine.register_participant 'alpha', Ruote::StorageParticipant

  start = Time.now

  pdef = Ruote.process_definition :name => 'mega' do
    #echo '/${f:index}/'
    alpha :unless => '${f:index} == 2000'
  end

  wfid = nil

  (1..2000).to_a.each_with_index do |i|
    wfid = engine.launch(pdef, 'index' => i)
  end

  puts "took #{Time.now - start} seconds to launch"

  #engine.context.worker.run_thread.join
  engine.wait_for(wfid)

else
  #
  # pure worker
  #

  puts "... standalone worker ..."

  worker = Ruote::Worker.new(storage)
  worker.run

end

