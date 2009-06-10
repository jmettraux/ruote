
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
        echo 'result : ${nada}'
      end
      sequence do
        bravo
      end
    end

    bravo = @engine.register_participant :bravo, Ruote::JoinableHashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    bravo.join

    fexp = @engine.expstorage[bravo.first.fei]

    assert_equal(
      ['0_0', ['sequence', {'sub0'=>nil}, [['echo', {'result : ${nada}'=>nil}, []]]]],
      fexp.lookup_variable('sub0'))
  end
end

