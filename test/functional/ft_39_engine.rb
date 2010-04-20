
#
# testing ruote
#
# Tue Apr 20 12:32:44 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/storage_participant'


class FtEngineTest < Test::Unit::TestCase
  include FunctionalBase

  def test_workitem

    pdef = Ruote.process_definition :name => 'my process' do
      alpha
    end

    sp = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal Ruote::Workitem, @engine.workitem("0_0!!#{wfid}").class
  end
end

