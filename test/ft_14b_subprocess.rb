
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'openwfe/def'
require 'flowtestbase'


class FlowTest14b < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  #
  # TEST 0

  def test_0

    dotest(
'''<process-definition name="subtest0" revision="0">

  <sequence>
    <subprocess ref="sub0" a="A" b="B" c="C" />
    <sub0 a="A" b="B" c="C" />
  </sequence>

  <process-definition name="sub0">
    <print>${a}${b}${c}</print>
  </process-definition>

</process-definition>''',
    "ABC\nABC")
  end


  #
  # TEST 1

  class SubTest1 < OpenWFE::ProcessDefinition

    sub1 "toto", :a => "A"

    process_definition :name => :sub1 do
      _print "${0} ${a}"
    end
  end

  def test_1

    dotest(SubTest1, 'toto A')
  end


  #
  # TEST 1b

  def test_1b

    dotest(
'''<process-definition name="subtest0" revision="0">

  <sequence>
    <subprocess ref="sub0" a="A">zero</subprocess>
    <sub0 a="A">rei</sub0>
  </sequence>

  <process-definition name="sub0">
    <print>${0} ${a}</print>
  </process-definition>

</process-definition>''',
    "zero A\nrei A")
  end


  #
  # TEST 2

  class SubTest2 < OpenWFE::ProcessDefinition
    def make

      sequence do
        sub1 do
          "a"
        end
        sub1 "c", "d"
      end

      process_definition :name => :sub1 do
        _print "${0} ${1}"
      end
    end
  end

  def test_2

    dotest SubTest2, "a \nc d"
  end


  #
  # TEST 3

  class SubTest3 < OpenWFE::ProcessDefinition

    subprocess "c", "d", :ref => :sub1

    process_definition :name => :sub1 do
      _print "${0} ${1}"
    end
  end

  def test_3

    dotest SubTest3, "c d"
  end

  #
  # TEST 4

  class Test4 < OpenWFE::ProcessDefinition
    sub0
    process_definition :name => 'sub0' do
      toto
    end
  end

  def test_4

    #log_level_to_debug

    @engine.register_participant "toto", OpenWFE::NullParticipant

    fei = launch Test4

    sleep 0.350

    #puts @engine.get_expression_storage
    assert_equal(7, @engine.get_expression_storage.size)

    @engine.cancel_process fei

    sleep 0.350

    assert_equal 1, @engine.get_expression_storage.size
  end

  #
  # TEST 5

  class Test5 < OpenWFE::ProcessDefinition
    sub0 :forget => true
    process_definition :name => "sub0" do
      toto
    end
  end

  def test_5

    #log_level_to_debug

    @engine.register_participant "toto", OpenWFE::NullParticipant

    fei = launch Test5

    sleep 0.350

    #puts @engine.get_expression_storage
    assert_equal 4, @engine.get_expression_storage.size

    @engine.cancel_process fei.wfid + ".0"
      # cancelling the remaining subprocess

    sleep 0.350

    assert_equal 1, @engine.get_expression_storage.size
  end

end

