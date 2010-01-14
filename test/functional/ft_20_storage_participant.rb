
#
# testing ruote
#
# Thu Dec  3 22:39:03 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/storage_participant'


class FtStorageParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant

    pdef = Ruote.process_definition :name => 'def0' do
      alpha
    end

    @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, @engine.storage.get_many('workitems').size

    alpha = Ruote::StorageParticipant.new
    alpha.context = @engine.context

    wi = alpha.first

    assert_equal Ruote::Workitem, wi.class

    alpha.reply(wi)

    wait_for(wfid)

    assert_nil @engine.process(wfid)
  end

  def test_purge

    pdef = Ruote.process_definition :name => 'def0' do
      alpha
    end

    @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, @engine.storage.get_many('workitems').size

    alpha = Ruote::StorageParticipant.new
    alpha.context = @engine.context

    assert !alpha.first.nil?

    alpha.purge!

    assert alpha.first.nil?
  end

  def test_find_by_wfid

    pdef = Ruote.process_definition :name => 'def0' do
      concurrence do
        alpha
        alpha
      end
    end

    @engine.register_participant :alpha, Ruote::StorageParticipant

    wfid = @engine.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)
      # wait for the two workitems

    alpha = Ruote::StorageParticipant.new
    alpha.context = @engine.context

    assert_equal 2, alpha.size
    assert_equal 2, alpha.by_wfid(wfid).size
  end

  CON_AL_BRAVO = Ruote.process_definition :name => 'con_al_bravo' do
    set 'f:place' => 'heiankyou'
    concurrence do
      sequence do
        set 'f:character' => 'minamoto no hirosama'
        alpha
      end
      sequence do
        set 'f:character' => 'seimei'
        set 'f:adversary' => 'doson'
        bravo
      end
    end
  end

  def test_find_by_participant

    @engine.register_participant :alpha, Ruote::StorageParticipant
    @engine.register_participant :bravo, Ruote::StorageParticipant

    wfid = @engine.launch(CON_AL_BRAVO)

    wait_for(:bravo)

    part = Ruote::StorageParticipant.new
    part.context = @engine.context

    assert_equal 2, part.size
    assert_equal 1, part.by_participant('alpha').size
    assert_equal 1, part.by_participant('bravo').size
  end

  def test_by_field

    @engine.register_participant :alpha, Ruote::StorageParticipant
    @engine.register_participant :bravo, Ruote::StorageParticipant

    wfid = @engine.launch(CON_AL_BRAVO)

    wait_for(:bravo)

    part = Ruote::StorageParticipant.new
    part.context = @engine.context

    assert_equal 2, part.size
    assert_equal 2, part.by_field('place').size
    assert_equal 2, part.by_field('character').size
    assert_equal 1, part.by_field('adversary').size
  end

  def test_by_field_and_value

    @engine.register_participant :alpha, Ruote::StorageParticipant
    @engine.register_participant :bravo, Ruote::StorageParticipant

    wfid = @engine.launch(CON_AL_BRAVO)

    wait_for(:bravo)

    part = Ruote::StorageParticipant.new
    part.context = @engine.context

    assert_equal 2, part.size
    assert_equal 0, part.by_field('place', 'nara').size
    assert_equal 2, part.by_field('place', 'heiankyou').size
    assert_equal 1, part.by_field('character', 'minamoto no hirosama').size
  end
end

