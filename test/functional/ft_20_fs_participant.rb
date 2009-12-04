
#
# Testing Ruote (OpenWFEru)
#
# Mon Jul 20 22:07:33 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/fs_participant'


class FtFsParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_fs_participant_consume_reply

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

  def test_fs_participant_update

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

    alpha.update(wi)

    assert_equal 3, Dir.new('work/fs_participants/').entries.size
    assert_equal 1, alpha.size
  end

  def test_find_by_wfid

    pdef = Ruote.process_definition :name => 'def0' do
      concurrence do
        alpha
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::FsParticipant

    wfid0 = @engine.launch(pdef)
    wfid1 = @engine.launch(pdef)

    sleep 0.500

    assert_equal 4, alpha.size

    assert_equal 2, alpha.by_wfid(wfid0).size
    assert_equal Ruote::Workitem, alpha.by_wfid(wfid1).first.class
  end

  def test_find_all

    pdef = Ruote.process_definition :name => 'def0' do
      concurrence do
        alpha
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::FsParticipant

    assert_equal [], alpha.all

    wfid0 = @engine.launch(pdef)
    wfid1 = @engine.launch(pdef)

    sleep 0.500

    alpha.all do |wi|
      assert_kind_of Ruote::Workitem, wi
    end
  end

  def test_by_participant

    pdef = Ruote.process_definition :name => 'def0' do
      concurrence do
        alpha
        beta
      end
    end

    fs = @engine.register_participant :alpha, Ruote::FsParticipant
    @engine.register_participant :beta, fs

    wfid = @engine.launch(pdef)

    sleep 0.500

    assert_equal 1, fs.by_participant('alpha').size
    assert_equal 1, fs.by_participant('beta').size
  end

  def test_purge

    pdef = Ruote.process_definition :name => 'def0' do
      concurrence do
        alpha
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::FsParticipant

    wfid0 = @engine.launch(pdef)
    wfid1 = @engine.launch(pdef)

    sleep 0.500

    assert_equal 4, alpha.size

    alpha.purge!

    assert_equal 0, alpha.size
  end
end

