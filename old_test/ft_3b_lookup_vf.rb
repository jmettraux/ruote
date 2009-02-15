
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Wed Jan  9 22:52:06 JST 2008
#

require File.dirname(__FILE__) + '/flowtestbase'

# DONE


class FlowTest3b < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  class Def0 < OpenWFE::ProcessDefinition
    sequence do

      # variable

      set :v => "v0", :val => "val0"

      equals :variable => "v0", :other_value => "val0"
      _print "${f:__result__}"

      equals :variable_value => "v0", :other_value => "val0"
      _print "${f:__result__}"

      equals :var_value => "v0", :other_value => "val0"
      _print "${f:__result__}"

      equals :v_value => "v0", :other_value => "val0"
      _print "${f:__result__}"

      equals :var => "v0", :other_value => "val0"
      _print "${f:__result__}"

      equals :v => "v0", :other_value => "val0"
      _print "${f:__result__}"

      equals :v => "v0", :other_val => "val0"
      _print "${f:__result__}"

      equals :val => "val0", :other_val => "val0"
      _print "${f:__result__}"

      # field

      set :f => "f0", :val => "f_val0"

      equals :field_value => "f0", :other_value => "f_val0"
      _print "${f:__result__}"

      equals :f_value => "f0", :other_value => "f_val0"
      _print "${f:__result__}"

      equals :field => "f0", :other_value => "f_val0"
      _print "${f:__result__}"

      equals :field => "f0", :value => "f_val0"
      _print "${f:__result__}"

      equals :f => "f0", :other_value => "f_val0"
      _print "${f:__result__}"

      # damn, I could use a Rufus subprocess... but it's 11pm...
      # copy, paste is just fine for a test...
    end
  end

  def test_0

    dotest Def0, ([ "true" ] * 13).join("\n")
  end

end

