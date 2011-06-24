
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

    alpha.proceed(wi)

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

  def test_all

    n = 3

    pdef = Ruote.process_definition :name => 'def0' do
      alpha
    end

    @engine.register_participant :alpha, Ruote::StorageParticipant

    wfids = []

    n.times { wfids << @engine.launch(pdef) }

    while @engine.storage_participant.size < n
      sleep 0.400
    end

    assert_equal(
      [ Ruote::Workitem ] * 3,
      @engine.storage_participant.all.collect { |wi| wi.class })

    assert_equal 3, @engine.storage_participant.size
    assert_equal 3, @engine.storage_participant.all(:count => true)
  end

  def test_by_wfid

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
    assert_equal 2, alpha.by_wfid(wfid, :count => true)
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

    assert_equal 1, @part.by_participant('alpha', :count => true)
    assert_equal 1, @part.by_participant('bravo', :count => true)
  end

  def test_by_participant_and_limit

    3.times do |i|
      @engine.storage.put(
        'type' => 'workitems',
        '_id' => "0_#{i}!ffffff!20101219-yamamba",
        'participant_name' => 'al',
        'wfid' => '20101220-yamamba',
        'fields' => {})
    end
    3.times do |i|
      @engine.storage.put(
        'type' => 'workitems',
        '_id' => "1_#{i}!eeeeee!20101219-yamamba",
        'participant_name' => 'bob',
        'wfid' => '20101220-yamamba',
        'fields' => {})
    end

    sp = @engine.storage_participant

    assert_equal 6, sp.size

    assert_equal 0, sp.by_participant('nada', :limit => 2).size
    assert_equal 2, sp.by_participant('al', :limit => 2).size
    assert_equal 2, sp.by_participant('al', :skip => 0, :limit => 2).size
    assert_equal 2, sp.by_participant('al', :skip => 1, :limit => 2).size

    assert_equal 2, sp.by_participant('bob', :skip => 0, :limit => 2).size
    assert_equal 1, sp.by_participant('bob', :skip => 2, :limit => 2).size
  end

  def test_by_field

    prepare_al_bravo

    assert_equal 2, @part.size
    assert_equal Ruote::Workitem, @part.by_field('place').first.class
    assert_equal 2, @part.by_field('place').size
    assert_equal 2, @part.by_field('character').size
    assert_equal 1, @part.by_field('adversary').size
    assert_equal 2, @part.by_field('character', :count => true)
  end

  def test_by_field_and_limit

    prepare_al_bravo

    assert_equal(
      %w[ bravo ],
      @part.by_field(
        'character', :skip => 1, :limit => 2
      ).collect { |wi| wi.participant_name })
  end

  def test_by_field_and_value

    prepare_al_bravo

    assert_equal 2, @part.size
    assert_equal 0, @part.by_field('place', 'nara').size
    assert_equal 2, @part.by_field('place', 'heiankyou').size
    assert_equal 1, @part.by_field('character', 'minamoto no hirosama').size
    assert_equal 2, @part.by_field('place', 'heiankyou', :count => true)
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

    assert_equal 4, @part.query(:count => true)

    page0 =
      @part.query('place' => 'heiankyou', :limit => 2).collect { |wi|
        "#{wi.fei.wfid}-#{wi.participant_name}" }
    page1 =
      @part.query('place' => 'heiankyou', :offset => 2, :limit => 2).collect { |wi|
        "#{wi.fei.wfid}-#{wi.participant_name}" }

    assert_equal 4, (page0 + page1).sort.uniq.size

    assert_equal(
      2, @part.query('place' => 'heiankyou', :participant => 'alpha').size)

    assert_equal 2, @part.query(:participant => 'alpha').size
    assert_equal 2, @part.query(:participant => 'alpha', :count => true)
  end

  # Issue reported in
  # http://groups.google.com/group/openwferu-users/browse_thread/thread/d0557c58f8636c9
  #
  def test_query_and_limit

    n = 7

    n.times do |i|
      @engine.storage.put(
        'type' => 'workitems',
        '_id' => "0_#{i}!ffffff!20101219-yamamba",
        'participant_name' => 'al',
        'wfid' => '20101219-yamamba',
        'fields' => {})
    end
    n.times do |i|
      @engine.storage.put(
        'type' => 'workitems',
        '_id' => "1_#{i}!ffffff!20101219-yamamba",
        'participant_name' => 'bob',
        'wfid' => '20101219-yamamba',
        'fields' => {})
    end

    sp = @engine.storage_participant

    assert_equal n * 2, sp.query({}).size
    assert_equal n * 2, sp.query(:offset => 0, :limit => 100).size
    assert_equal n * 2, sp.query(:skip => 0, :limit => 100).size

    assert_equal n / 2, sp.query(:offset => 0, :limit => n / 2).size
    assert_equal n / 2, sp.query(:skip => 0, :limit => n / 2).size

    assert_equal(
      n / 2,
      sp.query(:participant_name => 'al', :offset => 0, :limit => n / 2).size)
    assert_equal(
      n / 2,
      sp.query(:participant_name => 'al', :skip => 0, :limit => n / 2).size)

    assert_equal(
      [ 'al' ] * (n / 2),
      sp.query(
        :participant_name => 'al', :skip => 0, :limit => n / 2
      ).collect { |wi| wi.participant_name })
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

    participant.proceed(items.first)

    wait_for(:step_two)

    items = participant.by_wfid(wfid)

    assert_equal 1, participant.size
    assert_equal 1, items.size
    assert_equal 'step_two', items.first.participant_name

    participant.proceed(items.first)

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

  def test_by_fei

    sp = @engine.register_participant 'alpha', Ruote::StorageParticipant

    wfid = @engine.launch(Ruote.process_definition { alpha })

    wait_for(:alpha)

    wi = sp.first

    assert_equal wi, sp.by_fei(wi)
    assert_equal wi, sp.by_fei(wi.fei)
    assert_equal wi, sp.by_fei(wi.to_h)
    assert_equal wi, sp.by_fei(wi.fei.to_h)
    assert_equal wi, sp.by_fei(wi.fei.to_storage_id)
  end

  def test_engine_storage_participant

    @engine.register_participant 'step_.*', Ruote::StorageParticipant

    wfid = @engine.launch(Ruote.process_definition { step_one })

    wait_for(:step_one)

    assert_equal 1, @engine.storage_participant.size
    assert_equal 'step_one', @engine.storage_participant.first.participant_name
  end

  class MyParticipant < Ruote::StorageParticipant
    def consume(wi)
      @context.tracer << "consume\n"
      super
    end
    #def update(wi)
    #  @context.tracer << "update\n"
    #  super
    #end
  end

  def test_override_update

    pdef = Ruote.define do
      alpha
    end

    @engine.register do
      alpha MyParticipant
    end

    @engine.launch(pdef)
    @engine.wait_for(:alpha)

    part = @engine.participant(:alpha)

    initial_rev = part.first.h['_rev']

    part.update(part.first)

    assert_not_equal initial_rev, part.first.h['_rev']
    assert_equal %w[ consume ], @tracer.to_a
  end

  def test_fetch

    @engine.register do
      catchall
    end

    @engine.launch(Ruote.define do
      alpha
    end)

    @engine.wait_for(:alpha)

    fei = @engine.storage_participant.first.fei

    wi = @engine.storage_participant.send(:fetch, fei)

    assert_equal Hash, wi.class
  end

  # StorageParticipant includes Enumerable, therefore, it should respond
  # to select...
  #
  # http://groups.google.com/group/openwferu-users/t/6b594fd141f5d4b1
  #
  def test_select

    @engine.register { catchall }

    @engine.launch(Ruote.define do
      concurrence { alpha; bravo; charly }
    end)

    while @engine.storage_participant.size < 3; end

    assert_equal(
      1,
      @engine.storage_participant.select { |wi|
        wi.participant_name == 'bravo'
      }.size)
  end
end

