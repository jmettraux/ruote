
#
# testing ruote
#
# Fri May 15 09:51:28 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class FtErrorsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_error

    pdef = Ruote.process_definition do
      nada
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size

    pss = @engine.processes

    assert_equal 1, pss.size
    assert_equal 1, pss.first.errors.size
  end

  # asm and jpr5 use that sometimes
  #
  def test_error_reapply

    pdef = Ruote.process_definition do
      nada
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    ps = @engine.process(wfid)

    exp = ps.expressions.find { |fe| fe.class == Ruote::Exp::RefExpression }

    assert_not_nil exp

    @engine.register_participant :nada do |workitem|
      @tracer << 'done.'
    end

    @engine.re_apply(exp.fei)
    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s

    assert_equal 0, @engine.storage.get_many('errors').size
  end

  def test_error_replay

    pdef = Ruote.process_definition do
      nada
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    ps = @engine.process(wfid)

    err = ps.errors.first

    @engine.replay_at_error(err)

    wait_for(wfid)
    ps = @engine.process(wfid)

    #p ps

    assert_equal 1, ps.errors.size
      # only one error

    err1 = ps.errors.first

    assert_not_equal err.at, err1.at
      # not the same error

    assert_equal 1, @engine.storage.get_many('errors').size
  end

  def test_error_fix_then_replay

    pdef = Ruote.process_definition do
      nada
    end

    @engine.register_participant :alpha do
      @tracer << "alpha\n"
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)
    ps = @engine.process(wfid)

    err = ps.errors.first
    assert_equal [ 'nada', { 'ref' => 'nada' }, [] ], err.tree

    err.tree = [ 'alpha', {}, [] ]
    @engine.replay_at_error(err)
    wait_for(wfid)

    assert_nil @engine.process(wfid)

    assert_equal 'alpha', @tracer.to_s

    # check if error is really gone from error journal...

    assert_equal [], @engine.storage.get_many('errors')
  end

  def test_error_in_participant

    pdef = Ruote.process_definition do
      sequence do
        alpha
        echo 'done.'
      end
    end

    count = 0

    @engine.register_participant :alpha do
      count += 1
      @tracer << "alpha\n"
      raise "something went wrong" if count == 1
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    sleep 0.250 # grrr...

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size

    @engine.replay_at_error(ps.errors.first)

    wait_for(wfid)

    assert_equal %w[ alpha alpha done. ].join("\n"), @tracer.to_s
  end

  def test_error_in_do_no_thread_participant

    pdef = Ruote.process_definition do
      sequence do
        alpha
        echo 'done.'
      end
    end

    count = 0

    alpha = @engine.register_participant :alpha do
      count += 1
      @tracer << "alpha\n"
      raise "something went wrong" if count == 1
    end
    alpha.do_not_thread = true

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size

    @engine.replay_at_error(ps.errors.first)

    wait_for(wfid)

    assert_equal %w[ alpha alpha done. ].join("\n"), @tracer.to_s
  end

  class WeakCancelParticipant
    include Ruote::LocalParticipant

    def initialize (opts)
    end
    def consume (workitem)
      # losing it
    end
    def do_not_thread
      true
    end
    def cancel (fei, flavour)
      raise "failure in #cancel"
    end
  end

  def test_error_in_participant_cancel

    pdef = Ruote.process_definition do
      alpha
    end

    @engine.register_participant 'alpha', WeakCancelParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    @engine.cancel_process(wfid)

    wait_for(wfid)

    ps = @engine.process(wfid)

    #puts ps.errors.first.trace
    assert_equal 1, ps.errors.size
    assert_equal 2, ps.expressions.size

    @engine.kill_process(wfid)

    wait_for(wfid)

    assert_nil @engine.process(wfid)
  end

  def test_errors_and_subprocesses

    pdef = Ruote.process_definition do
      sequence do
        sub0
        echo 'done.'
      end
      define 'sub0' do
        alpha
      end
    end

    count = 0

    alpha = @engine.register_participant :alpha do
      count += 1
      @tracer << "alpha\n"
      raise "something went wrong" if count == 1
    end
    alpha.do_not_thread = true

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size

    err = ps.errors.first

    assert_equal wfid, err.fei.wfid
    assert_not_nil err.fei.sub_wfid

    @engine.replay_at_error(err)

    wait_for(wfid)

    assert_equal %w[ alpha alpha done. ].join("\n"), @tracer.to_s
  end

  def test_process_cancellation

    pdef = Ruote.process_definition do
      nada
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    assert_equal 1, @engine.process(wfid).errors.size

    @engine.cancel_process(wfid)

    wait_for(wfid)

    assert_nil @engine.process(wfid)
    assert_equal [], @engine.storage.get_many('errors')
  end

  def test_forgotten_subprocess

    pdef = Ruote.process_definition do
      sequence do
        sub0 :forget => true
        echo 'done.'
      end
      define 'sub0' do
        error 'broken wing'
      end
    end

    wfid = @engine.launch(pdef)
    wait_for(wfid)
    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s

    ps = @engine.process(wfid)
    assert_equal 3, ps.expressions.size
    assert_equal 1, ps.errors.size

    @engine.replay_at_error(ps.errors.first)
    wait_for(wfid)

    assert_nil @engine.process(wfid)
  end

  #def test_ps_to_h
  #  pdef = Ruote.process_definition do
  #    error 'nada'
  #  end
  #  #noisy
  #  wfid = @engine.launch(pdef)
  #  wait_for(wfid)
  #  ps = @engine.process(wfid)
  #  es = ps.to_h['errors']
  #  e = es.first
  #  assert_equal 1, es.size
  #  assert_equal 'reply', e['msg']['action']
  #  assert_equal wfid, e['msg']['fei']['wfid']
  #  assert_equal 8, e.size
  #end

  def test_error_intercepted

    pdef = Ruote.process_definition do
      nada
    end

    wfid = @engine.launch(pdef)

    r = @engine.wait_for(wfid)

    assert_equal 'RuntimeError', r['error_class']
    assert_equal "unknown participant or subprocess 'nada'", r['error_message']
    assert_equal Array, r['error_backtrace'].class
  end
end

