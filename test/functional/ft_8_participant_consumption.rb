
#
# Testing Ruote (OpenWFEru)
#
# Wed Jun 10 11:03:26 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtParticipantConsumptionTest < Test::Unit::TestCase
  include FunctionalBase

  def test_tag

    pdef = Ruote.process_definition do
      sequence do
        alpha
      end
    end

    @engine.register_participant :alpha do |workitem|
      @tracer << "#{workitem.participant_name}\n"
    end

    #noisy

    assert_trace(pdef, 'alpha')

    assert_equal 1, logger.log.select { |e| e[2][:pname] == 'alpha' }.size
  end
end

