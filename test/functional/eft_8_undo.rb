
#
# testing ruote
#
# Sun Jun 14 14:48:03 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class EftUndoTest < Test::Unit::TestCase
  include FunctionalBase

  def test_undo_ref

    pdef = Ruote.define do
      concurrence do
        alpha :tag => 'kilroy'
        undo :ref => 'kilroy'
      end
      echo 'over.'
    end

    alpha = @dashboard.register(:alpha, Ruote::StorageParticipant)

    wfid = @dashboard.launch(pdef)
    r = @engine.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 'over.', @tracer.to_s

    assert_equal 0, alpha.size

    assert_equal 1, logger.log.select { |e| e['action'] == 'entered_tag' }.size
    assert_equal 1, logger.log.select { |e| e['action'] == 'cancel' }.size
    assert_equal 1, logger.log.select { |e| e['action'] == 'left_tag' }.size

    assert_equal 1, r['variables']['__past_tags__'].size

    kilroy = r['variables']['__past_tags__'].first

    assert_equal 'kilroy', kilroy[0]
    assert_equal 'cancelled', kilroy[2]
  end

  def test_undo

    pdef = Ruote.process_definition do
      concurrence do
        alpha :tag => :kilroy
        #undo :kilroy
        cancel :kilroy
      end
      echo 'over'
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    assert_trace %w[ over ], pdef

    assert_equal 0, alpha.size

    assert_equal 1, logger.log.select { |e| e['action'] == 'entered_tag' }.size
    assert_equal 1, logger.log.select { |e| e['action'] == 'cancel' }.size
    assert_equal 1, logger.log.select { |e| e['action'] == 'left_tag' }.size
  end

  def test_undo_parent

    pdef = Ruote.process_definition do
      sequence :tag => :richard do
        cancel :richard
        echo 'out'
      end
      echo '.'
    end

    assert_trace '.', pdef
  end

  def test_undo_missing_tag

    pdef = Ruote.process_definition do
      cancel :nada
      echo '.'
    end

    assert_trace '.', pdef
  end

  def test_undo_tag_pointing_nowhere

    pdef = Ruote.process_definition do
      set 'v:nada' => []
      cancel :nada
      echo '.'
    end

    assert_trace '.', pdef
  end

  def test_undo_tag_pointing_to_missing_fei

    pdef = Ruote.process_definition do
      set 'v:nada' => { 'wfid' => '${wfid}', 'expid' => '${expid}', 'engine_id' => '${engine_id}' }
      cancel :nada
      echo '.'
    end

    assert_trace '.', pdef
  end

  def test_undo_no_tag

    pdef = Ruote.process_definition do
      cancel
      echo 'x'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 'x', @tracer.to_s
  end

  def test_kill

    @dashboard.register :alpha, Ruote::StorageParticipant

    pdef = Ruote.define do
      concurrence do
        alpha :tag => :kilroy, :on_cancel => :report
        kill :kilroy
      end
      echo 'over.'
      define 'report' do
        echo 'xxx'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 'over.', @tracer.to_s
  end
end

