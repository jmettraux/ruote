
#
# Testing Ruote (OpenWFEru)
#
# Wed Jun 10 17:41:23 JST 2009
#

require File.dirname(__FILE__) + '/base'

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
      ['0_0', ['sequence', {'sub0'=>nil}, [['bravo', {}, []], ['echo', {'result : ${v:nada}'=>nil}, []]]]],
      fexp.lookup_variable('sub0'))

    bravo.reply(bravo.first)
    wait_for(:bravo)

    fexp = @engine.expstorage[bravo.first.fei]

    assert_equal(
      ['sequence', {'sub0'=>nil}, [['bravo', {}, []], ['echo', {'result : ${v:nada}'=>nil}, []]]],
      fexp.parent.tree)
  end
end

