
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#
# Sat Jan  5 22:57:53 JST 2008
#

require 'flowtestbase'


class FlowTest81 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # Test 0
  #

  class Def0 < OpenWFE::ProcessDefinition

    sequence do

      exp :name => "p0"
      exp :name => "sub0"

      exp :name => "sequence" do
        p0
        sub0
      end

      set :var => "a", :value => { "ref" => "p0" }
      exp :name => "participant", :variable_attributes => "a"

      exp :default => "p0"
      exp :name => " ", :default => "p0"
    end

    process_definition :name => "sub0" do
      _print "sub0"
    end
  end

  def test_0

    @engine.register_participant :p0 do
      @tracer << "p0\n"
    end

    dotest Def0, %w{ p0 sub0 p0 sub0 p0 p0 p0 }.join("\n")
  end

end

