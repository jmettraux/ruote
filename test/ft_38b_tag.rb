
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'openwfe/def'
require 'openwfe/participants'

require 'flowtestbase'


class FlowTest38b < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #end


  #
  # test 4
  #

  class TestTag4 < OpenWFE::ProcessDefinition
    sequence do
      sequence :tag => "seq0" do
        peekin
      end
      peekout
    end
  end

  def test_tag_4

    #log_level_to_debug

    @engine.register_participant :peekin do |fexp, wi|

      fei = fexp.fei

      assert_equal 0, @engine.get_variables.size

      assert_equal 2, @engine.get_variables(fei.wfid).size
      assert_equal 1, @engine.process_status(fei.wfid).tags.size
      assert_equal "seq0", @engine.process_status(fei.wfid).tags.to_s
      assert_not_nil @engine.get_variables(fei.wfid)["seq0"]

      @tracer << "peekin\n"
    end

    @engine.register_participant :peekout do |fexp, wi|

      fei = fexp.fei

      assert_equal 1, @engine.get_variables(fei.wfid).size
      assert_equal 0, @engine.process_status(fei.wfid).tags.size
      assert_equal "", @engine.process_status(fei.wfid).tags.to_s

      @tracer << "peekout\n"
    end

    dotest TestTag4, "peekin\npeekout"
  end

  # test 5 moved to ft_38c ...

  #
  # test 6
  #

  class TestTag6 < OpenWFE::ProcessDefinition

    concurrence do
      peek :tag => "A"
      peek :tag => "B"
    end
  end

  def test_6

    @engine.register_participant :peek do |fexp, wi|

      wfid = fexp.fei.parent_workflow_instance_id

      #puts @engine.get_variables(wfid).keys.inspect
      @tracer << @engine.process_status(wfid).tags.to_s
    end

    dotest TestTag6, [ 'AAB', 'BAB', 'ABAB' ]
  end

  #
  # test 7 (milestone)
  #

  class TestTag7 < OpenWFE::ProcessDefinition
    concurrence do
      sequence do
        participant0
        participant1 :tag => "milestone"
        participant2
      end
      sequence do
        #wait :until => "'${milestone}' != ''", :frequency => "300"
        wait :until => "${milestone} is set", :frequency => "300"
        participant3
      end
    end
  end

  class OpenWFE::HashParticipant
    def proceed_first
      proceed first_workitem
    end
  end
    #
    # just added a shortcut method for testing purpose

  def test_7

    #log_level_to_debug

    ps = (0..3).collect do |i|

      @engine.register_participant(
        "participant#{i}", OpenWFE::HashParticipant)
    end

    fei = launch TestTag7

    sleep 0.350

    assert_equal 1, ps[0].size
    assert_equal 0, ps[1].size
    assert_equal 0, ps[2].size
    assert_equal 0, ps[3].size

    ps[0].proceed_first

    sleep 0.700 # why so much ? persistence...

    assert_equal 0, ps[0].size
    assert_equal 1, ps[1].size
    assert_equal 0, ps[2].size
    assert_equal 1, ps[3].size

    @engine.cancel_process fei.wfid

    sleep 0.500
  end

end

