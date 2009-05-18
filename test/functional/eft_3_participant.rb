
#
# Testing Ruote (OpenWFEru)
#
# Wed May 13 11:14:08 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant

    pdef = Ruote.process_definition do
      participant :ref => 'alpha'
    end

    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end

    #noisy
    verbose

    assert_trace pdef, 'alpha'
    assert_equal 1, logger.log.select { |e| e[1] == :dispatching }.size
    assert_equal 1, logger.log.select { |e| e[1] == :received }.size
  end
end

