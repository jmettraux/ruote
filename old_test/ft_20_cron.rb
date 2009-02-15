
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest20 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # Test 0
  #

  class TestDefinition0 < OpenWFE::ProcessDefinition
    process_definition :name => "rs0", :revision => "0" do
      concurrence :count => 1 do
        cron :tab => "* * * * *", :name => "cron" do
          participant :cron_event
        end
        sequence do
          _print "before"
          _sleep :for => "61s"
          _print "after"
        end
      end
    end
  end

  def test_0

    @engine.register_participant(:cron_event) do |fexp, wi|
      @tracer << "#{fexp.class.name}\n"
    end

    dotest(
      TestDefinition0,
      %w{ before OpenWFE::ParticipantExpression after }.join("\n"))
      #62)
  end

end

