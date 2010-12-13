
#
# testing ruote
#
# Mon Jun 15 12:58:12 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class EftRedoTest < Test::Unit::TestCase
  include FunctionalBase

  def test_redo

    pdef = Ruote.process_definition do
      sequence :tag => 'seq' do
        alpha
        _redo :ref => 'seq'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    alpha.reply(alpha.first)
    wait_for(:alpha)

    alpha.reply(alpha.first)
    wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal 0, ps.errors.size
    assert_equal 3, ps.expressions.size

    assert_equal 3, logger.log.select { |e| e['action'] == 'entered_tag' }.size
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

    #@engine.noisy = true

    assert_trace '.', pdef
  end

  def test_redo_tag_pointing_to_missing_fei

    pdef = Ruote.process_definition do
      set 'v:nada' => { 'wfid' => '${wfid}', 'expid' => '${expid}', 'engine_id' => '${engine_id}' }
      _redo :nada
      echo '.'
    end

    #@engine.noisy = true

    assert_trace '.', pdef
  end
end

