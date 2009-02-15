
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest40 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  #
  # Test 0
  #

  class TestDefined40a0 < OpenWFE::ProcessDefinition
    sequence do

      defined :field => "nada"
      _print "${f:__result__}"

      set :field => "nada", :value => "stuff"

      defined :field => "nada"
      _print "${f:__result__}"
      defined :field_value => "nada"
      _print "${f:__result__}"

      defined :field_match => "^na.*"
      _print "${f:__result__}"
      defined :field_match => "^Na.*"
      _print "${f:__result__}"
      defined :field_match => "da$"
      _print "${f:__result__}"

      undefined :field_value => "nada"
      _print "${f:__result__}"
      undefined :field_value => "other"
      _print "${f:__result__}"
    end
  end

  def test_0

    dotest(
      TestDefined40a0,
      %w{ false true true true false true false true }.join("\n"))
  end

end

