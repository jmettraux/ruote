#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon May  5 09:28:28 JST 2008
#

require 'rubygems'

require 'flowtestbase'

require 'openwfe/def'


class FlowTest86 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition

    set_fields :value => {
      "a" => "f:a",
      "b" => "f:b",
    }

    sequence do

      set :var => "a", :val => "v:a"
      set :var => "c", :val => "v:c"

      _print "${f:a}"
      _print "${v:a}"

      _print "${field:a}"
      _print "${variable:a}"

      _print "${vf:a}"
      _print "${fv:a}"

      _print "${vf:b}"
      _print "${fv:b}"
      _print "${vf:c}"
      _print "${fv:c}"

      _print "${r:1+2}"
      _print "${ru:4+3}"
    end
  end

  def test_0

    dotest(
      Test0,
      %w{ f:a v:a f:a v:a v:a f:a f:b f:b v:c v:c 3 7 }.join("\n"))
  end


end

