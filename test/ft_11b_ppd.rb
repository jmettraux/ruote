
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require 'rubygems'

require 'flowtestbase'
require 'openwfe/def'


class FlowTest11b < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # Test 0
  #
  # bug #9905 : "NPE" was raised...
  #

  class TestDefinition0 < OpenWFE::ProcessDefinition
    def make
      _print "ok"
    end
  end

  def test_0
    dotest TestDefinition0.new, "ok"
  end

  #
  # Test 1
  #

  class TestDefinition1 < OpenWFE::ProcessDefinition
    _print "ok"
  end

  def test_1
    dotest TestDefinition1, "ok"
  end

end

