
#
# testing ruote
#
# Fri May 15 09:51:28 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class FtErrorsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_error

    pdef = Ruote.process_definition do
      nada
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    ps = @dashboard.process(wfid)

    assert_equal 1, ps.errors.size

    pss = @dashboard.processes

    assert_equal 1, pss.size
    assert_equal 1, pss.first.errors.size
  end

  # asm and jpr5 use that sometimes
  #
  def test_error_reapply

    pdef = Ruote.process_definition do
      nada
    end

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)

    ps = @dashboard.process(wfid)

    exp = ps.expressions.find { |fe| fe.class == Ruote::Exp::RefExpression }

    assert_not_nil exp

    @dashboard.register_participant :nada do |workitem|
      tracer << 'done.'
    end

    @dashboard.re_apply(exp.fei)
    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s

    assert_equal 0, @dashboard.storage.get_many('errors').size
  end

  def test_error_replay

    pdef = Ruote.process_definition do
      nada
    end

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)

    ps = @dashboard.process(wfid)

    err = ps.errors.first

    @dashboard.replay_at_error(err)

    wait_for(wfid)
    ps = @dashboard.process(wfid)

    #p ps

    assert_equal 1, ps.errors.size
      # only one error

    err1 = ps.errors.first

    assert_not_equal err.at, err1.at
      # not the same error

    assert_equal 1, @dashboard.storage.get_many('errors').size
  end

  def test_error_fix_then_replay

    pdef = Ruote.process_definition do
      nada
    end

    @dashboard.register_participant :alpha do
      tracer << "alpha\n"
    end

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)
    ps = @dashboard.process(wfid)

    err = ps.errors.first
    assert_equal [ 'nada', { 'ref' => 'nada' }, [] ], err.tree

    err.tree = [ 'alpha', {}, [] ]
    @dashboard.replay_at_error(err)
    wait_for(wfid)

    assert_nil @dashboard.process(wfid)

    assert_equal 'alpha', @tracer.to_s

    # check if error is really gone from error journal...

    assert_equal [], @dashboard.storage.get_many('errors')
  end

  def test_error_in_participant

    pdef = Ruote.process_definition do
      sequence do
        alpha
        echo 'done.'
      end
    end

    @dashboard.context.stash[:count] = 0

    @dashboard.register_participant :alpha do
      stash[:count] += 1
      tracer << "alpha\n"
      raise "something went wrong" if stash[:count] == 1
    end

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    sleep 0.250 # grrr...

    ps = @dashboard.process(wfid)

    assert_equal 1, ps.errors.size

    @dashboard.replay_at_error(ps.errors.first)

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

    @dashboard.context.stash[:count] = 0

    alpha = @dashboard.register_participant :alpha, 'do_not_thread' => true do
      stash[:count] += 1
      tracer << "alpha\n"
      raise "something went wrong" if stash[:count] == 1
    end

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

    assert_equal 1, ps.errors.size

    @dashboard.replay_at_error(ps.errors.first)

    wait_for(wfid)

    assert_equal %w[ alpha alpha done. ].join("\n"), @tracer.to_s
  end

  class WeakCancelParticipant
    include Ruote::LocalParticipant

    def initialize(opts)
    end
    def consume(workitem)
      # losing it
    end
    def do_not_thread
      true
    end
    def cancel(fei, flavour)
      raise "failure in #cancel"
    end
  end

  def test_error_in_participant_cancel

    pdef = Ruote.process_definition do
      alpha
    end

    @dashboard.register_participant 'alpha', WeakCancelParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    @dashboard.cancel_process(wfid)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

    #puts ps.errors.first.trace
    assert_equal 1, ps.errors.size
    assert_equal 2, ps.expressions.size

    @dashboard.kill_process(wfid)

    wait_for(wfid)

    assert_nil @dashboard.process(wfid)
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

    @dashboard.context.stash[:count] = 0

    alpha = @dashboard.register_participant :alpha, :do_not_thread => true do
      stash[:count] += 1
      tracer << "alpha\n"
      raise "something went wrong" if stash[:count] == 1
    end

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

    assert_equal 1, ps.errors.size

    err = ps.errors.first

    assert_equal wfid, err.fei.wfid
    assert_not_nil err.fei.subid

    @dashboard.replay_at_error(err)

    wait_for(wfid)

    assert_equal %w[ alpha alpha done. ].join("\n"), @tracer.to_s
  end

  def test_process_cancellation

    pdef = Ruote.process_definition do
      nada
    end

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    assert_equal 1, @dashboard.process(wfid).errors.size

    @dashboard.cancel_process(wfid)

    wait_for(wfid)

    assert_nil @dashboard.process(wfid)
    assert_equal [], @dashboard.storage.get_many('errors')
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

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)
    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s

    ps = @dashboard.process(wfid)
    assert_equal 3, ps.expressions.size
    assert_equal 1, ps.errors.size

    @dashboard.replay_at_error(ps.errors.first)
    wait_for(wfid)

    assert_nil @dashboard.process(wfid)
  end

  def test_error_intercepted

    pdef = Ruote.process_definition do
      nada
    end

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(wfid)

    assert_equal 'error_intercepted', r['action']
    assert_equal 'RuntimeError', r['error']['class']
    assert_equal "unknown participant or subprocess 'nada'", r['error']['message']
    assert_equal Array, r['error']['trace'].class
    assert_equal [ 'nada', { 'ref' => 'nada' }, [] ], r['error']['tree']
  end

  def test_replay_at_error_fei

    @dashboard.register { catchall }

    wfid = @dashboard.launch(Ruote.define do
      error 'alpha'
      error 'bravo'
    end)

    @dashboard.wait_for(wfid)

    err = @dashboard.ps(wfid).errors.first
    assert_match /alpha/, err.message
    fei = err.fei

    @dashboard.replay_at_error(fei)

    @dashboard.wait_for(wfid)

    err = @dashboard.ps(wfid).errors.first
    assert_match /bravo/, err.message
  end

  class MyError < RuntimeError
    def ruote_details
      'where the devil is'
    end
  end

  def test_error_details

    @dashboard.register :alpha do |workitem|
      raise FtErrorsTest::MyError
    end

    wfid = @dashboard.launch(Ruote.define do
      alpha
    end)

    @dashboard.wait_for('error_intercepted')

    assert_equal 'where the devil is',  @dashboard.ps(wfid).errors.first.details

    #p @dashboard.ps(wfid)
  end
end

