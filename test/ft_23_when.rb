
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'rubygems'

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest23 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # Test 0
  #

  class TestDefinition0 < OpenWFE::ProcessDefinition
    process_definition :name => "when0", :revision => "0" do
      concurrence do
        _when :test => "${v:done} == true", :frequency => "2s" do
          _print "ok"
        end
        sequence do
          _sleep "500"
          _set :variable => "done", :value => "true"
          _print "done"
        end
      end
    end
  end

  def test_0

    dotest TestDefinition0, "done\nok"
  end

  #
  # Test 1
  #

  class TestWhen1 < OpenWFE::ProcessDefinition
    concurrence do
      _when :frequency => "2s" do
        sequence do
          #reval "puts '___ equals : ' + fei.wfid"
          _equals :value => "${done}", :other_value => "true"
        end
        sequence do
          #reval "puts '___ consequence : ' + fei.wfid"
          _print "ok"
        end
      end
      sequence do
        _sleep "500"
        _set :variable => "done", :value => "true"
        _print "done"
      end
    end
  end

  def test_1

    dotest TestWhen1, "done\nok"
  end

end

