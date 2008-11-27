
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Sep 20 23:40:10 JST 2008
#

require 'flowtestbase'


class FlowTest90 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    _print "${var0}"
  end

  def test_0
    @engine.launch Test0, :variables => { 'var0' => 'a' }
    sleep 0.350
    assert 'a', @tracer.to_s
  end
end

