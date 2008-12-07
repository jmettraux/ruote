
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Thu Mar 20 09:23:03 JST 2008
#

require File.dirname(__FILE__) + '/flowtestbase'

require 'openwfe/def'


class FlowTest85 < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #end

  #
  # TEST 0

  class TestDefinition0 < OpenWFE::ProcessDefinition
    participant "toto", :arg0 => "0", :arg1 => [ 1, 2 ]
  end

  def test_0

    @engine.register_participant "toto" do |fexp, workitem|
      #p fexp.raw_representation
      #p workitem.attributes
      @tracer << workitem.params["arg1"].inspect
    end

    dotest TestDefinition0, "[1, 2]"
  end

end

