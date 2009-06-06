
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
    wait
    ps = @engine.process_status(wfid)

    assert_equal 1, ps.errors.size
  end

  def test_error_replay

    pdef = Ruote.process_definition do
      nada
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)
    ps = @engine.process_status(wfid)

    err = ps.errors.first

    @engine.replay_at_error(err)

    wait_for(wfid)
    ps = @engine.process_status(wfid)

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
    ps = @engine.process_status(wfid)

    err = ps.errors.first
    assert_equal [ 'nada', {}, [] ], err.tree

    err.tree = [ 'alpha', {}, [] ]
    @engine.replay_at_error(err)
    wait_for(wfid)

    assert_nil @engine.process_status(wfid)

    assert_equal 'alpha', @tracer.to_s
  end
end

