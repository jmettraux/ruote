
#
# Testing Ruote (OpenWFEru)
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

    bravo = @engine.register_participant :bravo, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:bravo)

    fexp = @engine.expstorage[bravo.first.fei]

    assert_equal(
      [ '0_0',
        ['define', {'sub0'=>nil}, [['bravo', {}, []], ['echo', {'result : ${v:nada}'=>nil}, []]]] ],
      fexp.lookup_variable('sub0'))

    bravo.reply(bravo.first)
    wait_for(:bravo)

    fexp = @engine.expstorage[bravo.first.fei]

    assert_equal(
      ['define', {'sub0'=>nil}, [['bravo', {}, []], ['echo', {'result : ${v:nada}'=>nil}, []]]],
      fexp.parent.tree)

    assert_equal 1, logger.log.select { |e| e[1] == :launch_sub }.size
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

    sleep 0.500

    assert_equal 2, wfids.uniq.size
  end
end

