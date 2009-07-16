
#
# Testing Ruote (OpenWFEru)
#
# Wed Jun 10 11:03:26 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtParticipantConsumptionTest < Test::Unit::TestCase
  include FunctionalBase

  def test_workitems_dispatching_message

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

    Thread.pass
      # making sure the reply to the participant expression is intercepted
      # as well

    assert_equal 2, logger.log.select { |e| e[2][:pname] == 'alpha' }.size
  end

  def test_missing_participant_name

    pdef = Ruote.process_definition do
      sequence do
        participant
      end
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size
    assert_equal 'no participant name specified', ps.errors.first.error_message
  end

  def test_dot_star

    pdef = Ruote.process_definition do
      sequence do
        alpha
      end
    end

    @engine.register_participant '.*' do |workitem|
      @tracer << "#{workitem.participant_name} #{workitem.fei.expid}\n"
    end

    assert_trace(pdef, 'alpha 0_0_0')
  end
end

