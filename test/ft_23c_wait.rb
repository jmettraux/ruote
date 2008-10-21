
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest23c < Test::Unit::TestCase
  include FlowTestBase

  #
  # Test 0
  #

  class Wait0c < OpenWFE::ProcessDefinition
    sequence do
      concurrence do
        sequence do
          wait :until => "${done} == true", :frequency => "500"
          _print "after wait"
        end
        sequence do
          _sleep "200"
          _print "before done"
          _set :variable => "done", :value => "true"
        end
      end
      _print "over"
    end
  end

  def test_0

    #log_level_to_debug

    dotest Wait0c, [ 'before done', 'after wait', 'over' ].join("\n")
  end

  #
  # Test 1
  #

  class Wait1c < OpenWFE::ProcessDefinition
    sequence do
      concurrence do
        sequence do
          wait :frequency => "500" do
            equals :variable_value => "done", :other_value => "true"
          end
          _print "after wait"
        end
        sequence do
          _sleep "200"
          _print "before done"
          _set :variable => "done", :value => "true"
        end
      end
      _print "over"
    end
  end

  def test_1

    log_level_to_debug

    dotest Wait1c, [ 'before done', 'after wait', 'over' ].join("\n")
  end

end

