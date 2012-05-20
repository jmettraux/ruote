
#
# testing ruote
#
# Mon Jun 15 12:58:12 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class EftRedoTest < Test::Unit::TestCase
  include FunctionalBase

  def test_redo

    pdef = Ruote.process_definition do
      sequence :tag => 'seq' do
        alpha
        _redo :ref => 'seq'
      end
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)

    alpha.proceed(alpha.first)
    wait_for(:alpha)

    alpha.proceed(alpha.first)
    wait_for(:alpha)

    ps = @dashboard.process(wfid)

    assert_equal 0, ps.errors.size
    assert_equal 3, ps.expressions.size

    assert_equal 1, logger.log.select { |e| e['action'] == 'entered_tag' }.size
  end

  def test_redo_missing_tag

    pdef = Ruote.process_definition do
      _redo :nada
      echo '.'
    end

    assert_trace '.', pdef
  end

  def test_redo_tag_pointing_nowhere

    pdef = Ruote.process_definition do
      set 'v:nada' => []
      _redo :nada
      echo '.'
    end

    #@dashboard.noisy = true

    assert_trace '.', pdef
  end

  def test_redo_tag_pointing_to_missing_fei

    pdef = Ruote.process_definition do
      set 'v:nada' => { 'wfid' => '${wfid}', 'expid' => '${expid}', 'engine_id' => '${engine_id}' }
      _redo :nada
      echo '.'
    end

    #@dashboard.noisy = true

    assert_trace '.', pdef
  end

  def test_forget_and_redo

    pdef = Ruote.process_definition do
      sequence :tag => 'x' do
        alpha :forget => true
        _redo 'x'
      end
    end

    #noisy

    @dashboard.register 'alpha', Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    while @dashboard.storage_participant.size < 2
      sleep 0.350
    end

    assert_not_nil @dashboard.process(wfid)
    assert_equal [], @dashboard.errors
  end

  class Alpha
    include Ruote::LocalParticipant
    @@seen = false
    def consume(workitem)
      (workitem.fields['alpha'] ||= []) << 'x'
      workitem.fields['over'] = @@seen
      @@seen = true
      reply_to_engine(workitem)
    end
  end

  def test_redo__blank_workitem

    @dashboard.register do
      alpha Alpha
    end

    pdef = Ruote.process_definition do
      sequence :tag => 'x' do
        alpha
        _redo 'x', :unless => '${over}'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal %w[ x ], r['workitem']['fields']['alpha']
  end
end

