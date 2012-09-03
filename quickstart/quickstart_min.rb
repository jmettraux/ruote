
require 'rufus-json/automatic'
require 'ruote'
require 'ruote/storage/fs_storage'

ruote = Ruote::Dashboard.new(
  Ruote::Worker.new(
    Ruote::FsStorage.new('ruote_work')))

ruote.noisy = ENV['NOISY'] == 'true'

class Scout < Ruote::Participant
  def on_workitem
    sleep(rand)
    result =
      [ workitem.participant_name, (20 * rand + 1).to_i ]
    (workitem.fields['spotted'] ||= []) << result
    p result
    reply
  end
end

class Leader < Ruote::Participant
  def on_workitem
    workitem.fields['total'] =
      workitem.fields['spotted'].inject(0) { |t, f| t + f[1] }
    puts
    puts "bird:    " + workitem.fields['bird']
    puts "spotted: " + workitem.fields['spotted'].inspect
    puts "total:   " + workitem.fields['total'].inspect
    puts
    reply
  end
end

ruote.register /^scout_/, Scout
ruote.register /^leader_/, Leader

pdef = %q{
  define
    concurrence merge_type: concat
      scout_alice
      scout_bob
      scout_charly
    leader_doug
}

wfid = ruote.launch(
  pdef,
  'bird' => %w[ thrush cardinal dodo ].shuffle.first)

ruote.wait_for(wfid)

