
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sun Nov 30 17:25:55 JST 2008
#

require 'flowtestbase'


class FlowTest94 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  # testing the 'error' expression

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      _print '1'
      error 'something went wrong'
      _print '2'
    end
  end

  def test_0

    fei = @engine.launch Test0

    sleep 0.350

    assert_equal '1', @tracer.to_s

    ps = @engine.process_status(fei)

    #p ps.errors.values.first

    assert_equal 1, ps.errors.size
    assert_equal 'OpenWFE::ForcedError', ps.errors.values.first.error_class
    assert_equal 'something went wrong', ps.errors.values.first.stacktrace

    purge_engine
  end

  #
  # TEST 1

  class Test1 < OpenWFE::ProcessDefinition
    sequence do
      _print '1'
      error 'something went wrong', :if => 'false'
      _print '2'
      error 'something really went wrong', :if => false
      _print '3'
    end
  end

  def test_1

    dotest Test1, "1\n2\n3"
  end

  # TODO : add test for 'error replay'
end

