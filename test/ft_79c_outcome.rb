
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#
# Fri May  9 13:43:26 JST 2008
#

require 'flowtestbase'


class FlowTest79c < Test::Unit::TestCase
  include FlowTestBase

  class Test0 < OpenWFE::ProcessDefinition

    sequence do
      step :a0, :outcomes => [ :a1, :a2 ], :default => :a2
      _print "-"
      step :a1, :outcomes => [ :a1, :a2 ], :default => :whatever
      _print "-"
      step :a2, :outcomes => [ :a1, :a2 ]
    end

    define "a0" do
      sequence do
        _print "a0"
        #set :f => "outcome", :val => "a1"
        set :f => "outcome", :val => "whatever"
      end
    end
    define "a1" do
      sequence do
        _print "a1"
        set :f => "outcome", :val => "a2"
      end
    end
    define "a2" do
      sequence do
        _print "a2"
      end
    end
  end

  def test_0

    #log_level_to_debug

    #@engine.register_participant :alpha do |wi|
    #end

    dotest Test0, %w{ a0 a2 - a1 a2 - a2 }.join("\n")
  end
end

