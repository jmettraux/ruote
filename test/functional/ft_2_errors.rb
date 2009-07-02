
#
# Testing Ruote (OpenWFEru)
#
# Fri May 15 09:51:28 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class FtProcessStatusTest < Test::Unit::TestCase
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

    assert_not_equal err.when, err1.when
      # not the same error
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
    assert_equal [ 'nada', {}, [] ], err.tree

    err.tree = [ 'alpha', {}, [] ]
    @engine.replay_at_error(err)
    wait_for(wfid)

    assert_nil @engine.process(wfid)

    assert_equal 'alpha', @tracer.to_s
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

    wfid = @engine.launch(pdef)

    wait_for(wfid)

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
end

