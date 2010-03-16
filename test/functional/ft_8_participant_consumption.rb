
#
# testing ruote
#
# Wed Jun 10 11:03:26 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


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

    assert_trace('alpha', pdef)

    Thread.pass
      # making sure the reply to the participant expression is intercepted
      # as well

    assert_equal(
      2, logger.log.select { |e| e['participant_name'] == 'alpha' }.size)
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

    assert_equal(
      1, ps.errors.size)
    assert_equal(
      '#<ArgumentError: no participant name specified>', ps.errors[0].message)
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

    assert_trace('alpha 0_0_0', pdef)
  end

  def test_dispatch_time

    wis = []

    pdef = Ruote.process_definition { alpha; alpha }

    @engine.register_participant 'alpha' do |workitem|
      wis << workitem.to_h.dup
    end

    assert_trace('', pdef)

    assert_equal(
      String, wis.first['fields']['dispatched_at'].class)
    assert_not_equal(
      wis.first['fields']['dispathed_at'], wis.last['fields']['dispatched_at'])
  end
end

