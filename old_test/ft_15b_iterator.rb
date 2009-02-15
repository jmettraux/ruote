
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require 'rubygems'

require 'openwfe/def'
require 'openwfe/participants/participants'
require File.dirname(__FILE__) + '/flowtestbase'


class FlowTest15b < Test::Unit::TestCase
  include FlowTestBase

  #
  # Test 0
  #

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      set :field => "participant_list", :value => "a, b, c"
      iterator :on_value => "${f:participant_list}", :to_variable => "p" do
        participant "${p}"
      end
      _print "done."
    end
  end

  def test_0

    @engine.register_participant "." do |workitem|
      @tracer << workitem.participant_name
    end

    dotest Test0, "abcdone."
  end

  #
  # Test 1
  #

  def test_1

    @engine.register_participant ".", OpenWFE::NullParticipant

    fei = launch Test0

    sleep 0.350

    #puts @engine.get_expression_storage.to_s
    assert_equal 7, @engine.get_expression_storage.size
    assert_equal "", @tracer.to_s

    @engine.cancel_process fei

    sleep 0.350

    #puts @engine.get_expression_storage
    assert_equal 1, @engine.get_expression_storage.size
    assert_equal "", @tracer.to_s
  end

end

