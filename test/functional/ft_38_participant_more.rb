
#
# testing ruote
#
# Mon Apr 19 14:38:54 JST 2010
#
# Qcon Tokyo, special day
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/local_participant'


class FtParticipantMoreTest < Test::Unit::TestCase
  include FunctionalBase

  class DifficultParticipant
    include Ruote::LocalParticipant
    def initialize (opts)
    end
    def consume (workitem)
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

    @engine.register_participant :alpha, DifficultParticipant

    #noisy

    assert_trace(%w[ diff diff ], pdef)
  end

  class FightingParticipant
    include Ruote::LocalParticipant
    def initialize (opts)
    end
    def consume (workitem)
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

  # Reject and re_dispatch are aliases.
  #
  def test_participant_re_dispatch

    pdef = Ruote.process_definition do
      alpha
    end

    @engine.register_participant :alpha, FightingParticipant

    #noisy

    assert_trace(%w[ try0 try1 ], pdef)
  end

  class RetryParticipant
    include Ruote::LocalParticipant
    def initialize (opts)
      @opts = opts
    end
    def consume (workitem)
      try = workitem.fields['try'] || 0
      context.tracer << "#{Time.now.to_f}\n"
      workitem.fields['try'] = try + 1
      if (try == 0)
        re_dispatch(workitem, :in => @opts['delay'] || '1s')
      else
        reply(workitem)
      end
    end
    def cancel (fei, flavour)
      unschedule_re_dispatch(fei)
    end
  end

  # Reject and re_dispatch are aliases.
  #
  # re_dispatch with an :in or an :at parameter makes sure the dispatch is
  # performed once more, but a bit later (:in / :at timepoint).
  #
  def test_participant_re_dispatch_later

    pdef = Ruote.process_definition do
      alpha
    end

    @engine.register_participant :alpha, RetryParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    times = @tracer.to_s.split("\n").collect { |t| Float(t) }
    t = times.last - times.first

    assert t >= 1.0, "took less that 1 second"
    assert t < 2.0, "took more than 1.99 second"
  end

  # Making sure that when a process gets cancelled, its 'later' re-dispatches
  # are cancelled as well.
  #
  def test_participant_re_dispatch_later_cancel

    pdef = Ruote.process_definition do
      alpha
    end

    @engine.register_participant :alpha, RetryParticipant, 'delay' => '1m'

    #noisy

    wfid = @engine.launch(pdef)
    sleep 0.7

    @engine.cancel_process(wfid)
    wait_for(wfid)

    assert_equal 0, @engine.storage.get_many('schedules').size
  end

  BLACKBOARD = {}

  class StashingParticipant
    include Ruote::LocalParticipant
    def initialize (opts)
    end
    def consume (workitem)
      put(workitem.fei, 'token' => workitem.params['token'])
    end
    def cancel (fei, flavour)
      BLACKBOARD['token'] = get(fei, 'token')
      BLACKBOARD['all'] = get(fei)
    end
  end

  # Stashing lets a stateless participant 'stash' state via put() and get()
  # into the engine.
  #
  def test_stash

    BLACKBOARD.clear

    pdef = Ruote.process_definition do
      alpha :token => 'of esteem'
    end

    @engine.register_participant :alpha, StashingParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    sleep 0.350 # since wait_for(:alpha) releases too early sometimes

    ps = @engine.process(wfid)
    fexp = ps.expressions.find { |e| e.fei.expid == '0_0' }

    assert_equal({ 'token' => 'of esteem' }, fexp.h.stash)

    @engine.cancel_process(wfid)
    wait_for(wfid)

    assert_equal('of esteem', BLACKBOARD['token'])
    assert_equal({ 'token' => 'of esteem' }, BLACKBOARD['all'])
  end
end

