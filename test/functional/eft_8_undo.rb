
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

    pdef = Ruote.process_definition do
      concurrence do
        alpha :tag => 'kilroy'
        undo :ref => 'kilroy'
      end
      echo 'over'
    end

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    assert_trace %w[ over ], pdef

    assert_equal 0, alpha.size

    assert_equal 1, logger.log.select { |e| e['action'] == 'entered_tag' }.size
    assert_equal 1, logger.log.select { |e| e['action'] == 'cancel' }.size
    assert_equal 1, logger.log.select { |e| e['action'] == 'left_tag' }.size
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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

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

    #noisy

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

    #@engine.noisy = true

    assert_trace '.', pdef
  end

  def test_undo_tag_pointing_to_missing_fei

    pdef = Ruote.process_definition do
      set 'v:nada' => { 'wfid' => '${wfid}', 'expid' => '${expid}', 'engine_id' => '${engine_id}' }
      cancel :nada
      echo '.'
    end

    #@engine.noisy = true

    assert_trace '.', pdef
  end
end

