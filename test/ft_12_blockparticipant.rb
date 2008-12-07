
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest12 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  #
  # Test 0
  #

  class BpDef0 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test0", :revision => "0" do
        sequence do
          participant :ref => "block-participant"
          _print "done."
        end
      end
    end
  end

  def test_bp_0
    dotest(
      BpDef0,
      """the block participant received a workitem
done.""")
  end


  #
  # Test 1
  #

  class BpDef1 < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "test1", :revision => "0" do
        bp1a
      end
    end
  end

  def test_bp_1

    @engine.register_participant("bp1a") do |fexp, wi|
      @tracer << "bp1a : "
      @tracer << fexp.class.name
      @tracer << "\n"
    end

    dotest(
      BpDef1,
      """bp1a : OpenWFE::ParticipantExpression""")
  end


  #
  # Test 2
  #

  class BpDef2 < OpenWFE::ProcessDefinition
    sequence do
      bp
      _print "${f:__result__}"
    end
  end

  def test_bp_2

    @engine.register_participant("bp") do |fexp, wi|
      "a string result"
        #
        # the 'return' value of a block participant is stored
        # in the "__result__" field of the workitem
    end

    dotest(BpDef2, "a string result")
  end

end

