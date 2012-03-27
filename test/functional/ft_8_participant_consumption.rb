
#
# testing ruote
#
# Wed Jun 10 11:03:26 JST 2009
#

require File.expand_path('../base', __FILE__)


class FtParticipantConsumptionTest < Test::Unit::TestCase
  include FunctionalBase

  def test_workitems_dispatching_message

    pdef = Ruote.process_definition do
      sequence do
        alpha
      end
    end

    @dashboard.register_participant :alpha do |workitem|
      tracer << "#{workitem.participant_name}\n"
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for('dispatched', 'receive', 'terminated')

    assert_equal(
      'alpha',
      @tracer.to_s)

    assert_equal(
      %w[ dispatch dispatched receive ],
      logger.log.select { |e|
        e['participant_name'] == 'alpha'
      }.collect { |e|
        e['action']
      }.sort)
  end

  def test_missing_participant_name

    pdef = Ruote.process_definition do
      sequence do
        participant
      end
    end

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

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

    @dashboard.register_participant '.*' do |workitem|
      tracer << "#{workitem.participant_name} #{workitem.fei.expid}\n"
    end

    assert_trace('alpha 0_0_0', pdef)
  end

  def test_dispatch_time

    @dashboard.context.stash[:wis] = []

    pdef = Ruote.process_definition { alpha; alpha }

    @dashboard.register_participant 'alpha' do |workitem|
      stash[:wis] << workitem.to_h.dup
    end

    assert_trace('', pdef)

    assert_equal(
      String,
      @dashboard.context.stash[:wis].first['fields']['dispatched_at'].class)

    assert_not_equal(
      @dashboard.context.stash[:wis].first['fields']['dispathed_at'],
      @dashboard.context.stash[:wis].last['fields']['dispatched_at'])
  end

  class MyParticipant
    include Ruote::LocalParticipant

    def consume(workitem)
      reply_to_engine(workitem)
    end

    def do_not_thread(workitem)
      @context.tracer << workitem.fields['msg']
      true
    end
  end

  def test_do_not_thread_and_workitem

    pdef = Ruote.define do
      alpha
    end

    @dashboard.register_participant :alpha, MyParticipant

    wfid = @dashboard.launch(pdef, 'msg' => 'kilroy')

    @dashboard.wait_for(wfid)

    assert_equal 'kilroy', @tracer.to_s
  end
end

