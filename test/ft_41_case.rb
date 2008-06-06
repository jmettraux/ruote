
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest41 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  #
  # Test 0
  #

  class TestCase41a0 < OpenWFE::ProcessDefinition
    sequence do
      _case do
        reval "2 % 2 == 0"
        _print "ok 0"
      end
      _case do
        reval "2 % 2 == 1"
        _print "bad 1"
        _print "ok 1"
      end
      _case do
        reval "2 % 2 == 1"
        _print "bad 2"
        reval "2 % 2 == 0"
        _print "ok 2"
        _print "bad 2"
      end
      _case do
        reval "2 % 2 == 1"
        _print "bad 2b"
        reval "2 % 2 == 0"
        _print "ok 2b"
      end
      _case do
        reval "2 % 2 == 1"
        _print "bad 3"
        reval "2 % 2 == 3"
        _print "bad 3"
        _print "ok 3"
      end
    end
  end

  def test_0

    dotest(
      TestCase41a0,
      [ 'ok 0', 'ok 1', 'ok 2', 'ok 2b', 'ok 3' ].join("\n"))
  end


  #
  # Test 1
  #

  class TestCase41a1 < OpenWFE::ProcessDefinition
    sequence do

      _if :test => "1 == 1"
      _print "${f:__result__}"
    end
  end

  def test_1

    dotest TestCase41a1, 'true'
  end


  #
  # Test 2
  #

  class TestCase41a2 < OpenWFE::ProcessDefinition
    sequence do
      _case do
        _if :test => "1 == 1"
        _print "ok"
      end
      _case do
        _if :test => "false"
        _print "bad 1"
        _print "ok 1"
      end
    end
  end

  def test_2

    dotest TestCase41a2, "ok\nok 1"
  end

end

