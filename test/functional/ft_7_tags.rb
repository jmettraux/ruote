
#
# testing ruote
#
# Wed Jun 10 11:03:26 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/participant'


class FtTagsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_tag

    pdef = Ruote.process_definition do
      sequence :tag => 'main' do
        alpha :tag => 'part'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    ps = @engine.process(wfid)

    #p ps.variables
    #ps.expressions.each { |e| p [ e.fei, e.variables ] }
    assert_equal '0_0', ps.variables['main']['expid']
    assert_equal '0_0_0', ps.variables['part']['expid']

    #logger.log.each { |e| puts e['action'] }
    assert_equal 2, logger.log.select { |e| e['action'] == 'entered_tag' }.size

    alpha.reply(alpha.first)
    wait_for(wfid)

    assert_equal 2, logger.log.select { |e| e['action'] == 'left_tag' }.size
  end

  # making sure a tag is removed in case of on_cancel
  #
  def test_on_cancel

    pdef = Ruote.process_definition do
      sequence do
        sequence :tag => 'a', :on_cancel => 'decom' do
          alpha
        end
        alpha
      end
      define 'decom' do
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, @engine.process(wfid).tags.size

    fei = @engine.process(wfid).expressions.find { |e|
      e.fei.expid == '0_1_0'
    }.fei

    @engine.cancel_expression(fei)

    wait_for(:alpha)

    assert_equal 0, @engine.process(wfid).tags.size

    alpha.reply(alpha.first)

    wait_for(:alpha)

    assert_equal 0, @engine.process(wfid).tags.size
  end

  def test_unset_tag_when_parent_gone

    pdef = Ruote.process_definition do
      concurrence :count => 1 do
        alpha :tag => 'main'
        sequence do
          bravo
          undo :ref => 'main'
        end
      end
    end

    #@engine.noisy = true

    @engine.register :alpha, Ruote::NullParticipant
    @engine.register :bravo, Ruote::NoOpParticipant

    wfid = @engine.launch(pdef)

    @engine.wait_for(23)

    assert_nil @engine.process(wfid)
  end
end

