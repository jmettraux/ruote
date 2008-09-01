
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Thu Nov  1 15:21:34 JST 2007
#

require 'rubygems'

require 'openwfe/def'

require 'flowtestbase'


class FlowTest75 < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #end

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      set :field => "f0", :value => [ 'my', 'array' ]
      set :field => :f1, :value => [ 'my', 'array' ]
      _print "${f:f0.0}"
      _print "${f:f1.1}"
    end
  end

  def test_0

    dotest Test0, "my\narray"
  end

  #
  # TEST 1

  class Test1 < OpenWFE::ProcessDefinition
    sequence do
      set :field => "f0", :value => true
      _print "${r:workitem.f0.class.name}"
    end
  end

  def test_1

    dotest Test1, "TrueClass"
  end

  #
  # TEST 2

  class Test2 < OpenWFE::ProcessDefinition
    sequence do
      set :variable => "v0", :value => "alpha"
      set :variable => :v0, :value => "bravo"
      _print "${v0}"
      set :field => "f0", :value => "alpha"
      set :field => :f0, :value => "bravo"
      _print "${f:f0}"
    end
  end

  def test_2

    dotest Test2, "bravo\nbravo"
  end

  #
  # TEST 3

  #class Test3 < OpenWFE::ProcessDefinition
  #  sequence do
  #  end
  #end
  #def test_3
  #  dotest Test3, "6"
  #end

end

