
#
# testing ruote
#
# Wed Jun 10 17:41:23 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class FtSubprocessesTest < Test::Unit::TestCase
  include FunctionalBase

  def test_subprocess_tree_lookup

    pdef = Ruote.process_definition do
      define 'sub0' do
        bravo
        echo 'result : ${v:nada}'
      end
      sequence do
        bravo
        sub0
      end
    end

    bravo = @engine.register_participant :bravo, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:bravo)

    fexp = Ruote::Exp::FlowExpression.fetch(
      @engine.context, bravo.first.fei.to_h)

    assert_equal(
      [ '0_0',
        ['define', {'sub0'=>nil}, [['bravo', {}, []], ['echo', {'result : ${v:nada}'=>nil}, []]]] ],
      fexp.lookup_variable('sub0'))

    bravo.reply(bravo.first)
    wait_for(:bravo)

    fexp = Ruote::Exp::FlowExpression.fetch(
      @engine.context, bravo.first.fei.to_h)

    assert_equal(
      ['define', {'sub0'=>nil}, [['bravo', {}, []], ['echo', {'result : ${v:nada}'=>nil}, []]]],
      fexp.parent.tree)

    #logger.log.each { |e| puts e['action'] }
    assert_equal 2, logger.log.select { |e| e['action'] == 'launch' }.size
  end

  def test_next_sub_wfid

    pdef = Ruote.process_definition do
      sequence do
        sub0 :forget => true
        sub0 :forget => true
      end
      define 'sub0' do
        sub1 :forget => true
      end
      define 'sub1' do
        alpha
      end
    end

    wfids = []

    @engine.register_participant :alpha do |workitem|
      wfids << workitem.fei.sub_wfid
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)
    wait_for(3)

    assert_equal 2, wfids.size
    assert_equal 2, wfids.sort.uniq.size
  end

  def test_cancel_and_subprocess

    pdef = Ruote.process_definition do
      sequence do
        sub0
      end
      define 'sub0' do
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, alpha.size

    @engine.cancel_process(wfid)

    wait_for(wfid)

    assert_equal 0, alpha.size
  end

  def test_cancel_and_engine_variable_subprocess

    pdef = Ruote.process_definition do
      sequence do
        sub0
      end
    end

    @engine.variables['sub0'] = Ruote.process_definition do
      alpha
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, alpha.size

    @engine.cancel_process(wfid)

    wait_for(wfid)

    assert_equal 0, alpha.size
  end
end

