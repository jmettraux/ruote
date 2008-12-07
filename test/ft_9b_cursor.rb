
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Thu Nov 22 11:53:13 JST 2007
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest9b < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # Test 0
  #

  class Test0 < OpenWFE::ProcessDefinition
    cursor do
      set :v => "v0", :val => "x"
      _print "${v0}"
    end
  end

  def test_0

    dotest Test0, "x"
  end

  #
  # Test 1
  #

  #class Test1 < OpenWFE::ProcessDefinition
  #  cursor do
  #    my_participant
  #  end
  #end
  #def test_1
  #  @engine.register_participant :my_participant do |fexp, wi|
  #    #puts fexp.to_s
  #    #puts fexp.environment_id.to_s
  #    @tracer << "ok0\n" if fexp.environment_id.expid != fexp.fei.expid
  #    @tracer << "ok1\n" if fexp.environment_id.expid == "0.0"
  #    @tracer << "ok2\n" if fexp.environment_id.wfid + ".0" == fexp.fei.wfid
  #  end
  #  dotest Test1, "ok0\nok1\nok2"
  #end

  #
  # Test 2
  #

  class Test2 < OpenWFE::ProcessDefinition
    cursor do
      my_participant
    end
  end
  class MyParticipant
    include OpenWFE::LocalParticipant

    def initialize (tracer)
      @tracer = tracer
    end
    def consume (workitem)
      @tracer << "consume\n"
      @workitem = workitem
    end
    def cancel (cancelitem)
      @tracer << "cancel\n"
    end
  end

  def test_2

    #log_level_to_debug

    @engine.register_participant :my_participant, MyParticipant.new(@tracer)

    fei = launch Test2

    sleep 0.350

    @engine.cancel_process fei

    sleep 0.350

    assert(
      [ "consume\ncancel",
        "consume\ncancel\ncancel" ].include?(@tracer.to_s))

    assert_equal 1, @engine.get_expression_storage.size
  end

end

