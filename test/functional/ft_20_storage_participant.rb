
#
# testing ruote
#
# Thu Dec  3 22:39:03 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/part/storage_participant'


class FtStorageParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant

    pdef = Ruote.process_definition :name => 'def0' do
      alpha
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, @dashboard.storage.get_many('workitems').size

    alpha = Ruote::StorageParticipant.new
    alpha.context = @dashboard.context

    wi = alpha.first

    assert_equal Ruote::Workitem, wi.class

    wi = alpha[alpha.first.fei]
    assert_equal Ruote::Workitem, wi.class

    alpha.proceed(wi)

    wait_for(wfid)

    assert_nil @dashboard.process(wfid)
  end

  def test_purge

    pdef = Ruote.process_definition :name => 'def0' do
      alpha
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, @dashboard.storage.get_many('workitems').size

    alpha = Ruote::StorageParticipant.new
    alpha.context = @dashboard.context

    assert !alpha.first.nil?

    alpha.purge!

    assert alpha.first.nil?
  end

  def test_all

    n = 3

    pdef = Ruote.process_definition :name => 'def0' do
      alpha
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfids = []

    n.times { wfids << @dashboard.launch(pdef) }

    while @dashboard.storage_participant.size < n
      sleep 0.400
    end

    assert_equal(
      [ Ruote::Workitem ] * 3,
      @dashboard.storage_participant.all.collect { |wi| wi.class })

    assert_equal 3, @dashboard.storage_participant.size
    assert_equal 3, @dashboard.storage_participant.all(:count => true)
  end

  def test_by_wfid

    pdef = Ruote.process_definition :name => 'def0' do
      concurrence do
        alpha
        alpha
      end
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)
      # wait for the two workitems

    alpha = Ruote::StorageParticipant.new
    alpha.context = @dashboard.context

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

    @dashboard.register_participant :alpha, Ruote::StorageParticipant
    @dashboard.register_participant :bravo, Ruote::StorageParticipant

    @wfid = @dashboard.launch(CON_AL_BRAVO)

    wait_for(:bravo)

    @part = Ruote::StorageParticipant.new
    @part.context = @dashboard.context
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
      @dashboard.storage.put(
        'type' => 'workitems',
        '_id' => "0_#{i}!ffffff!20101219-yamamba",
        'participant_name' => 'al',
        'wfid' => '20101220-yamamba',
        'fields' => {})
    end
    3.times do |i|
      @dashboard.storage.put(
        'type' => 'workitems',
        '_id' => "1_#{i}!eeeeee!20101219-yamamba",
        'participant_name' => 'bob',
        'wfid' => '20101220-yamamba',
        'fields' => {})
    end

    sp = @dashboard.storage_participant

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

    wfid2 = @dashboard.launch(CON_AL_BRAVO, 'adversary' => 'B')
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
      @dashboard.storage.put(
        'type' => 'workitems',
        '_id' => "0_#{i}!ffffff!20101219-yamamba",
        'participant_name' => 'al',
        'wfid' => '20101219-yamamba',
        'fields' => {})
    end
    n.times do |i|
      @dashboard.storage.put(
        'type' => 'workitems',
        '_id' => "1_#{i}!ffffff!20101219-yamamba",
        'participant_name' => 'bob',
        'wfid' => '20101219-yamamba',
        'fields' => {})
    end

    sp = @dashboard.storage_participant

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

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.process_definition do
      alpha
    end)

    wait_for(:alpha)

    part = Ruote::StorageParticipant.new(@dashboard)

    assert_equal 1, part.size
  end

  def test_cancel

    pdef = Ruote.process_definition :name => 'def0' do
      alpha
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    @dashboard.cancel_process(wfid)

    wait_for(wfid)

    assert_nil @dashboard.process(wfid)
    assert_equal 0, Ruote::StorageParticipant.new(@dashboard).size
  end

  def test_shared_participant

    @dashboard.register_participant 'step_.*', Ruote::StorageParticipant

    wfid = @dashboard.launch(
      Ruote.process_definition { sequence { step_one; step_two } })

    wait_for(:step_one)

    participant = Ruote::StorageParticipant.new(@dashboard)

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

    assert_nil @dashboard.process(wfid)
  end

  def test_update_workitem

    @dashboard.register_participant 'alpha', Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.process_definition { alpha })

    alpha = Ruote::StorageParticipant.new(@dashboard)

    wait_for(:alpha)

    wi = alpha.first

    wi.fields['jidai'] = 'heian'

    alpha.update(wi)

    assert_equal 'heian', alpha.first.fields['jidai']
  end

  def test_registration

    pa = @dashboard.register_participant 'alpha', Ruote::StorageParticipant

    assert_equal Ruote::StorageParticipant, pa.class

    assert_equal [], pa.all
  end

  def test_various_args

    sp = @dashboard.register_participant 'alpha', Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.process_definition { alpha })

    wait_for(:alpha)

    wi = sp.first

    assert_equal wi, sp[wi]
    assert_equal wi, sp[wi.fei]
    assert_equal wi, sp[wi.to_h]
    assert_equal wi, sp[wi.fei.to_h]
    assert_equal wi, sp[wi.fei.to_storage_id]
  end

  def test_by_fei

    sp = @dashboard.register_participant 'alpha', Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.process_definition { alpha })

    wait_for(:alpha)

    wi = sp.first

    assert_equal wi, sp.by_fei(wi)
    assert_equal wi, sp.by_fei(wi.fei)
    assert_equal wi, sp.by_fei(wi.to_h)
    assert_equal wi, sp.by_fei(wi.fei.to_h)
    assert_equal wi, sp.by_fei(wi.fei.to_storage_id)
  end

  def test_engine_storage_participant

    @dashboard.register_participant 'step_.*', Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.process_definition { step_one })

    wait_for(:step_one)

    assert_equal 1, @dashboard.storage_participant.size
    assert_equal 'step_one', @dashboard.storage_participant.first.participant_name
  end

  class MyParticipant < Ruote::StorageParticipant
    def on_workitem
      @context.tracer << "on_workitem\n"
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

    @dashboard.register do
      alpha MyParticipant
    end

    @dashboard.launch(pdef)
    @dashboard.wait_for(:alpha)

    part = @dashboard.participant(:alpha)

    initial_rev = part.first.h['_rev']

    part.update(part.first)

    assert_not_equal initial_rev, part.first.h['_rev']
    assert_equal %w[ on_workitem ], @tracer.to_a
  end

  def test_fetch

    @dashboard.register do
      catchall
    end

    @dashboard.launch(Ruote.define do
      alpha
    end)

    @dashboard.wait_for(:alpha)

    fei = @dashboard.storage_participant.first.fei

    wi = @dashboard.storage_participant.send(:fetch, fei)

    assert wi.kind_of?(Hash)
  end

  # StorageParticipant includes Enumerable, therefore, it should respond
  # to select...
  #
  # http://groups.google.com/group/openwferu-users/t/6b594fd141f5d4b1
  #
  def test_select

    @dashboard.register { catchall }

    @dashboard.launch(Ruote.define do
      concurrence { alpha; bravo; charly }
    end)

    while @dashboard.storage_participant.size < 3; end

    assert_equal(
      1,
      @dashboard.storage_participant.select { |wi|
        wi.participant_name == 'bravo'
      }.size)
  end

  def test_reserve

    #@dashboard.noisy = true

    @dashboard.register { catchall }

    wfid = @dashboard.launch(Ruote.define do
      alpha
    end)

    while @dashboard.storage_participant.size < 1; end

    wi0 = @dashboard.storage_participant.first

    # #reserve yields the [updated] workitem when successful

    wi = @dashboard.storage_participant.first
    wi = @dashboard.storage_participant.reserve(wi, 'user0')

    assert_equal 'user0', wi.owner
    assert_not_equal wi0.h._rev, wi.h._rev # it's not the same wi

    # #reserve yields nil when failing

    wi = @dashboard.storage_participant.first
    wi = @dashboard.storage_participant.reserve(wi, 'user1')

    assert_equal nil, wi

    # #proceed raises when the owner is not the right one

    assert_raise(ArgumentError) do
      @dashboard.storage_participant.proceed(wi0)
    end

    wi = @dashboard.storage_participant.first
    @dashboard.storage_participant.proceed(wi)

    @dashboard.wait_for('terminated')

    # #proceed raises when the workitem is gone

    assert_raise(ArgumentError) do
      @dashboard.storage_participant.proceed(wi)
    end
  end

  def test_delegate

    #@dashboard.noisy = true

    @dashboard.register { catchall }

    wfid = @dashboard.launch(Ruote.define do
      alpha
    end)

    while @dashboard.storage_participant.size < 1; end

    wi0 = @dashboard.storage_participant.first

    # can't delegate when there is no owner

    assert_raise(ArgumentError) do
      @dashboard.storage_participant.delegate(wi0, 'user0')
    end

    # can't delegate if the owner is not the right one

    wi1 = @dashboard.storage_participant.reserve(wi0, 'user0')
    wi1.h.owner = 'user9'

    assert_raise(ArgumentError) do
      @dashboard.storage_participant.delegate(wi1, 'user0')
    end

    # it delegates alrighty

    wi1.h.owner = 'user0'
    wi2 = @dashboard.storage_participant.delegate(wi1, 'user1')

    assert_equal 'user1', wi2.h.owner

    # it's ok to delegate to nil (disowns workitem)

    wi = @dashboard.storage_participant.first
    x = @dashboard.storage_participant.delegate(wi, nil)

    wi = @dashboard.storage_participant.first

    assert_equal nil, wi.h.owner
  end

  def test_worklist

    assert_equal Ruote::StorageParticipant, @dashboard.storage_participant.class
    assert_equal Ruote::StorageParticipant, @dashboard.worklist.class
  end

  def test_flunk

    @dashboard.register :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.define do
      alpha
    end)

    @dashboard.wait_for('dispatched')

    assert_equal 1, @dashboard.storage_participant.size

    wi = @dashboard.storage_participant.first

    @dashboard.storage_participant.flunk(wi, ArgumentError, 'sorry?')

    r = @dashboard.wait_for(wfid)

    assert_equal 'error_intercepted', r['action']
    assert_equal 'ArgumentError', r['error']['class']
    assert_equal 'sorry?', r['error']['message']
    assert_match __FILE__, r['error']['trace'][1]

    assert_equal 0, @dashboard.storage_participant.size
  end

  def test_flunk_error_instance

    @dashboard.register :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.define do
      alpha
    end)

    @dashboard.wait_for('dispatched')

    assert_equal 1, @dashboard.storage_participant.size

    wi = @dashboard.storage_participant.first

    begin
      raise 'nada'
    rescue => e
      @dashboard.storage_participant.flunk(wi, e)
    end

    r = @dashboard.wait_for(wfid)

    assert_equal 'error_intercepted', r['action']
    assert_equal 'RuntimeError', r['error']['class']
    assert_equal 'nada', r['error']['message']
    assert_match __FILE__, r['error']['trace'].first

    assert_equal 0, @dashboard.storage_participant.size
  end

  def test_flunk_with_on_error

    @dashboard.register :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.define do
      sequence :on_error => 'report_error' do
        alpha
      end
      define 'report_error' do
        echo 'error...'
      end
    end)

    @dashboard.wait_for('dispatched')

    assert_equal 1, @dashboard.storage_participant.size

    wi = @dashboard.storage_participant.first

    @dashboard.storage_participant.flunk(wi, ArgumentError, 'pure fail')

    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 'error...', @tracer.to_s

    assert_equal 0, @dashboard.storage_participant.size
  end

  class IuriParticipant < Ruote::StorageParticipant
    def on_workitem
      super
      workitem.fields['count'] = 777
      do_update
    end
  end

  def test_do_update

    @dashboard.register :alpha, IuriParticipant

    wfid = @dashboard.launch(
      Ruote.define do
        alpha
      end)

    @dashboard.wait_for('dispatched')
    sleep 0.350

    wi = @dashboard.storage_participant.first

    assert_equal(777, wi.fields['count'])
  end
end

