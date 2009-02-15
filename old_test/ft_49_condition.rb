
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest49 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  #
  # Test 0
  #

  class TestCondition49a0 < OpenWFE::ProcessDefinition
    sequence do

      _if :test => "false"
      _print "0 ${f:__result__}"

      _if :test => "true; false"
      _print "1 ${f:__result__}"

      _if :test => "false; true"
      _print "2 ${f:__result__}"

      #_if :test => "print ''; true"
      _if :test => "''; true"
      _print "3 ${f:__result__}"

      #_if :test => "begin print ''; end; true"
      _if :test => "begin ''; end; true"
      _print "4 ${f:__result__}"

      unset :field => "__result__"

      _if :test => "true == "
      _print "5 ${f:__result__}"
      _if :test => " == true"
      _print "6 ${f:__result__}"
    end
  end

  def test_0

    log_level_to_debug

    dotest(
      TestCondition49a0,
      [ "0 false",
        "1 true",
        "2 true",
        "3 true",
        "4 true",
        "5 false",
        "6 false" ].join("\n"))
  end


  #
  # Test 1
  #

  class TestCondition49a1 < OpenWFE::ProcessDefinition
    sequence do
      _if :test => "true and false and false"
      _print "0 ${f:__result__}"
      _if :rtest => "true and true and true"
      _print "1 ${f:__result__}"
      _if :rtest => "false or false or true"
      _print "2 ${f:__result__}"
    end
  end

  def test_1

    dotest(
      TestCondition49a1,
      [ "0 false", "1 true", "2 true" ].join("\n"))
  end


  #
  # Test 2
  #

  class TestCondition49a2 < OpenWFE::ProcessDefinition
    sequence do
      _if :test => "true"
      _print "0 ${f:__result__}"
      _if :not => "false"
      _print "1 ${f:__result__}"
      _if :rnot => "1 > 3"
      _print "2 ${f:__result__}"

      unset :field => "__result__"

      _if :rnot => "1 > -1"
      _print "3 ${f:__result__}"

      _if :rtest => "workitem.is_a?(String)"
      _print "4 ${f:__result__}"

      _if :rtest => "wi.is_a?(InFlowWorkItem)"
      _print "5 ${f:__result__}"
    end
  end

  def test_2

    dotest(
      TestCondition49a2,
      [ "0 true",
        "1 true",
        "2 true",
        "3 false",
        "4 false",
        "5 true" ].join("\n"))
  end

end

