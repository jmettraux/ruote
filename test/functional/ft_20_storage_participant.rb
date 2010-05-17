
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

    wi = alpha[alpha.first.fei]
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

  def prepare_al_bravo

    @engine.register_participant :alpha, Ruote::StorageParticipant
    @engine.register_participant :bravo, Ruote::StorageParticipant

    @wfid = @engine.launch(CON_AL_BRAVO)

    wait_for(:bravo)

    @part = Ruote::StorageParticipant.new
    @part.context = @engine.context
  end

  def test_by_participant

    prepare_al_bravo

    assert_equal 2, @part.size
    #@part.by_participant('alpha').each { |wi| p wi }
    assert_equal Ruote::Workitem, @part.by_participant('alpha').first.class
    assert_equal 1, @part.by_participant('alpha').size
    assert_equal 1, @part.by_participant('bravo').size
  end

  def test_by_field

    prepare_al_bravo

    assert_equal 2, @part.size
    assert_equal Ruote::Workitem, @part.by_field('place').first.class
    assert_equal 2, @part.by_field('place').size
    assert_equal 2, @part.by_field('character').size
    assert_equal 1, @part.by_field('adversary').size
  end

  def test_by_field_and_value

    prepare_al_bravo

    assert_equal 2, @part.size
    assert_equal 0, @part.by_field('place', 'nara').size
    assert_equal 2, @part.by_field('place', 'heiankyou').size
    assert_equal 1, @part.by_field('character', 'minamoto no hirosama').size
  end

  def test_query

    prepare_al_bravo

    wfid2 = @engine.launch(CON_AL_BRAVO, 'adversary' => 'B')
    wait_for(:bravo)

    #@part.query({}).each { |wi| puts '-' * 80; p wi }

    assert_equal 4, @part.size
    assert_equal 4, @part.query({}).size
    assert_equal Ruote::Workitem, @part.query({}).first.class
    assert_equal 2, @part.query(:wfid => @wfid).size
    assert_equal 0, @part.query('place' => 'nara').size
    assert_equal 4, @part.query('place' => 'heiankyou').size
    assert_equal 2, @part.query(:wfid => @wfid, :place => 'heiankyou').size

    assert_equal(
      1,
      @part.query(:adversary => 'B', :place => 'heiankyou').size)

    assert_equal 2, @part.query('place' => 'heiankyou', :limit => 2).size
    assert_equal 4, @part.query('place' => 'heiankyou', :limit => 20).size

    page0 =
      @part.query('place' => 'heiankyou', :limit => 2).collect { |wi|
        "#{wi.fei.wfid}-#{wi.participant_name}" }
    page1 =
      @part.query('place' => 'heiankyou', :offset => 2, :limit => 2).collect { |wi|
        "#{wi.fei.wfid}-#{wi.participant_name}" }

    #p page0, page1
    assert_equal 4, (page0 + page1).sort.uniq.size

    assert_equal(
      2, @part.query('place' => 'heiankyou', :participant => 'alpha').size)
  end

  def test_initialize_engine_then_opts

    @engine.register_participant :alpha, Ruote::StorageParticipant

    wfid = @engine.launch(Ruote.process_definition do
      alpha
    end)

    wait_for(:alpha)

    part = Ruote::StorageParticipant.new(@engine)

    assert_equal 1, part.size
  end

  def test_cancel

    pdef = Ruote.process_definition :name => 'def0' do
      alpha
    end

    @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    @engine.cancel_process(wfid)

    wait_for(wfid)

    assert_nil @engine.process(wfid)
    assert_equal 0, Ruote::StorageParticipant.new(@engine).size
  end

  def test_shared_participant

    @engine.register_participant 'step_.*', Ruote::StorageParticipant

    wfid = @engine.launch(
      Ruote.process_definition { sequence { step_one; step_two } })

    wait_for(:step_one)

    participant = Ruote::StorageParticipant.new(@engine)

    items = participant.by_wfid(wfid)

    assert_equal 1, participant.size
    assert_equal 1, items.size
    assert_equal 'step_one', items.first.participant_name

    participant.reply(items.first)

    wait_for(:step_two)

    items = participant.by_wfid(wfid)

    assert_equal 1, participant.size
    assert_equal 1, items.size
    assert_equal 'step_two', items.first.participant_name

    participant.reply(items.first)

    wait_for(wfid)

    assert_nil @engine.process(wfid)
  end

  def test_update_workitem

    @engine.register_participant 'alpha', Ruote::StorageParticipant

    wfid = @engine.launch(Ruote.process_definition { alpha })

    alpha = Ruote::StorageParticipant.new(@engine)

    wait_for(:alpha)

    wi = alpha.first

    wi.fields['jidai'] = 'heian'

    alpha.update(wi)

    assert_equal 'heian', alpha.first.fields['jidai']
  end

  def test_registration

    pa = @engine.register_participant 'alpha', Ruote::StorageParticipant

    assert_equal Ruote::StorageParticipant, pa.class

    assert_equal [], pa.all
  end

  def test_various_args

    sp = @engine.register_participant 'alpha', Ruote::StorageParticipant

    wfid = @engine.launch(Ruote.process_definition { alpha })

    wait_for(:alpha)

    wi = sp.first

    assert_equal wi, sp[wi]
    assert_equal wi, sp[wi.fei]
    assert_equal wi, sp[wi.to_h]
    assert_equal wi, sp[wi.fei.to_h]
    assert_equal wi, sp[wi.fei.to_storage_id]
  end
end

