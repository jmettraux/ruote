
#
# Testing Ruote (OpenWFEru)
#
# Mon Jul 20 22:07:33 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/fs_participant'


class FtFsParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_fs_participant

    pdef = Ruote.process_definition :name => 'def0' do
      alpha
    end

    alpha = @engine.register_participant :alpha, Ruote::FsParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal 3, Dir.new('work/fs_participants/').entries.size
    assert_equal 1, alpha.size

    wi = alpha.first

    assert_equal Ruote::Workitem, wi.class

    alpha.reply(wi)

    wait_for(wfid)

    assert_equal 2, Dir.new('work/fs_participants/').entries.size
    assert_equal 0, alpha.size
  end
end

