
#
# testing ruote
#
# Mon Apr 19 14:38:54 JST 2010
#
# Qcon Tokyo, special day (12/19 plus tard)
#

require File.expand_path('../base', __FILE__)

require 'ruote/part/local_participant'


class FtParticipantMoreTest < Test::Unit::TestCase
  include FunctionalBase

  #
  # tests about reject / re_dispatch

  def test_re_dispatch_count_is_initially_zero

    @dashboard.register { catchall }

    wfid = @dashboard.launch(Ruote.define { alpha })
    r = @dashboard.wait_for(:alpha)

    assert_equal 0, r['workitem']['re_dispatch_count']
  end

  class CountingParticipant
    include Ruote::LocalParticipant
    def on_workitem
      context.tracer << "#{workitem.re_dispatch_count}\n"
      if workitem.re_dispatch_count < 5
        re_dispatch
      else
        reply
      end
    end
  end

  def test_re_dispatch_count_is_incremented_at_each_re_dispatch

    @dashboard.register { counter CountingParticipant }

    wfid = @dashboard.launch(Ruote.define { counter })

    @dashboard.wait_for(wfid)

    assert_equal %w[ 0 1 2 3 4 5 ], @tracer.to_a
  end

  class DifficultParticipant
    include Ruote::LocalParticipant
    def initialize(opts)
    end
    def consume(workitem)
      context.tracer << "diff\n"
      if workitem.fields['rejected'].nil?
        workitem.fields['rejected'] = true
        reject(workitem)
      else
        reply_to_engine(workitem)
      end
    end
  end

  # Reject and re_dispatch are aliases.
  #
  def test_participant_reject

    pdef = Ruote.process_definition do
      alpha
    end

    @dashboard.register_participant :alpha, DifficultParticipant

    assert_trace(%w[ diff diff ], pdef)
  end

  # https://groups.google.com/d/topic/openwferu-users/_k-VIQwMvXw/discussion
  #
  def test_re_dispatch_outside_of_participant

    @dashboard.register :alpha, Ruote::StorageParticipant

    pdef = Ruote.process_definition do
      alpha
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for('dispatched')

    wi = @dashboard.storage_participant.first

    @dashboard.storage_participant.re_dispatch(wi, :in => '100')

    sleep 10
  end

  class ReluctantParticipant
    include Ruote::LocalParticipant
    def initialize(opts)
    end
    def consume(workitem)
      context.tracer << "x\n"
      if workitem.fields['re_dispatched'].nil?
        workitem.fields['re_dispatched'] = true
        re_dispatch
      else
        reply_to_engine(workitem)
      end
    end
  end

  # Reject and re_dispatch are aliases.
  #
  def test_participant_re_dispatch_no_params

    @dashboard.register_participant :alpha, ReluctantParticipant

    assert_trace(%w[ x x ], Ruote.define { alpha })
  end

  class FightingParticipant
    include Ruote::LocalParticipant
    def initialize(opts)
    end
    def consume(workitem)
      try = workitem.fields['try'] || 0
      context.tracer << "try#{try}\n"
      workitem.fields['try'] = try + 1
      if (try == 0)
        re_dispatch(workitem)
      else
        reply(workitem)
      end
    end
  end

  def test_participant_re_dispatch

    pdef = Ruote.process_definition do
      alpha
    end

    @dashboard.register_participant :alpha, FightingParticipant

    #noisy

    assert_trace(%w[ try0 try1 ], pdef)
  end

  class RetryParticipant
    include Ruote::LocalParticipant
    def initialize(opts)
      @opts = opts
    end
    def consume(workitem)
      try = workitem.fields['try'] || 0
      context.tracer << "#{Time.now.to_f}\n"
      workitem.fields['try'] = try + 1
      if (try == 0)
        re_dispatch(workitem, :in => @opts['delay'] || '1s')
      else
        reply(workitem)
      end
    end
    def cancel(fei, flavour)
      unschedule_re_dispatch(fei)
    end
  end

  # re_dispatch with an :in or an :at parameter makes sure the dispatch is
  # performed once more, but a bit later (:in / :at timepoint).
  #
  def test_participant_re_dispatch_later

    pdef = Ruote.process_definition do
      alpha
    end

    @dashboard.register_participant :alpha, RetryParticipant

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)

    times = @tracer.to_s.split("\n").collect { |t| Float(t) }
    t = times.last - times.first

    assert t >= 1.0, "took less that 1 second"
    assert t < 2.8, "took more than 2.8 second"
  end

  # Making sure that when a process gets cancelled, its 'later' re-dispatches
  # are cancelled as well.
  #
  def test_participant_re_dispatch_later_cancel

    pdef = Ruote.process_definition do
      alpha
    end

    @dashboard.register_participant :alpha, RetryParticipant, 'delay' => '1m'

    #noisy

    wfid = @dashboard.launch(pdef)
    sleep 0.7

    @dashboard.cancel_process(wfid)
    wait_for(wfid)

    assert_equal 0, @dashboard.storage.get_many('schedules').size
  end

  #
  # tests about stash_put and stash_get

  BLACKBOARD = {}

  class StashingParticipant
    include Ruote::LocalParticipant
    def initialize(opts)
    end
    def consume(workitem)
      put('token0' => workitem.params['token0'])
      put('token1', workitem.params['token1'])
    end
    def cancel(fei, flavour)
      BLACKBOARD['token0'] = get('token0')
      BLACKBOARD['all'] = get
    end
  end

  # Stashing lets a stateless participant 'stash' state via put() and get()
  # into the engine.
  #
  def test_stash

    BLACKBOARD.clear

    pdef = Ruote.process_definition do
      alpha :token0 => 'of esteem', :token1 => 'of whatever'
    end

    @dashboard.register_participant :alpha, StashingParticipant

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)
    wait_for(1)

    ps = @dashboard.process(wfid)
    fexp = ps.expressions.find { |e| e.fei.expid == '0_0' }

    assert_equal(
      { 'token0' => 'of esteem', 'token1' => 'of whatever' },
      fexp.h.stash)

    @dashboard.cancel_process(wfid)
    wait_for(wfid)

    assert_equal(
      'of esteem',
      BLACKBOARD['token0'])
    assert_equal(
      { 'token0' => 'of esteem', 'token1' => 'of whatever' },
      BLACKBOARD['all'])
  end

  class Doubtful
    include Ruote::LocalParticipant

    def on_workitem
      context.tracer << "canceled:#{is_canceled?}\n"
      context.tracer << "gone:#{is_gone?}\n"
      sleep 5
      context.tracer << "cancelled:#{is_cancelled?}\n"
      context.tracer << "gone:#{is_gone?}\n"
    end

    def on_cancel
      # nothing
    end
  end

  def test_is_cancelled

    @dashboard.register :alpha, Doubtful

    pdef = Ruote.define do
      alpha
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)
    sleep 1.0 # making sure on_workitem reaches its sleep

    @dashboard.cancel(@dashboard.ps(wfid).expressions.last)

    @dashboard.wait_for(wfid)

    sleep 10

    assert_equal(
      %w[ canceled:false gone:false cancelled:true gone:true ],
      @tracer.to_a)
  end

  class Robust
    include Ruote::LocalParticipant

    def on_workitem
      context.tracer << "on_workitem\n"
      sleep 5
      workitem.fields['toto'] = 'seen'
      reply
    end

    def on_cancel
      context.tracer << "on_cancel\n"
      false
    end
  end

  def test_on_cancel_returning_false

    @dashboard.register :rob, Robust

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define { rob })

    @dashboard.wait_for(:rob)

    @dashboard.cancel(@dashboard.ps(wfid).expressions.last)

    r = @dashboard.wait_for(wfid)

    assert_equal 'seen', r['workitem']['fields']['toto']
    assert_equal %w[ on_cancel on_workitem ], @tracer.to_a.sort
  end
end

