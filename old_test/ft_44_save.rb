
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest44 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  #
  # Test 0
  #

  class TestCase44a0 < OpenWFE::ProcessDefinition
    sequence do
      set :field => "f", :value => "v"
      save :to_field => "saved"
      #pp_workitem
      _print "${f:saved.f}"
    end
  end

  def test_0

    dotest TestCase44a0, "v"
  end


  #
  # Test 1
  #

  class TestCase44a1 < OpenWFE::ProcessDefinition
    sequence do

      set :field => "f", :value => "field_value"
      save :to_variable => "v"

      #pp_workitem
      #_print "${r:fexp.lookup_variable('v').f}"
        #
        # doesn't work in case of ptest

      print_var
    end
  end

  def test_1

    @engine.register_participant :print_var do |fexp, wi|
      @tracer << fexp.lookup_variable('v').f.to_s
    end

    dotest TestCase44a1, "field_value"
  end

end

