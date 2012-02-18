
#
# testing ruote
#
# Thu Dec 10 14:08:30 JST 2009
#

require File.expand_path('../../test_helper', __FILE__)

require 'ruote'


class UtWaitLoggerTest < Test::Unit::TestCase

  def setup
    @engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new))
    @engine.register :alpha, Ruote::StorageParticipant
  end
  def teardown
    @engine.shutdown
  end

  def test_wait_for_participant

    #@engine.noisy = true

    pdef = Ruote.process_definition :name => 'test' do
      alpha
    end

    @engine.launch(pdef)
    msg = @engine.wait_for(:alpha)

    assert_equal 1, @engine.storage_participant.size

    assert_not_nil msg
    assert_not_nil msg['workitem']
    assert_equal 'dispatch', msg['action']
  end

  def test_wait_for_action

    #@engine.noisy = true

    pdef = Ruote.process_definition :name => 'test' do
      alpha
    end

    @engine.launch(pdef)

    msg = @engine.wait_for('apply')

    assert_equal 'apply', msg['action']

    msg = @engine.wait_for('dispatch')

    assert_equal 'dispatch', msg['action']
  end

  def test_wait_for_muliple_things

    d0 = Ruote.define do
      7.times { noop }
    end
    d1 = Ruote.define do
      7.times { noop }
      error 'oh crap'
    end

    #@engine.noisy = true

    i0 = @engine.launch(d0)
    i1 = @engine.launch(d1)

    r = @engine.wait_for(i0, i1)

    assert_includes [ i0, i1 ], r['wfid']
    assert_includes %w[ terminated error_intercepted ], r['action']
  end

  def test_or_error

    @engine.register :alpha, Ruote::NullParticipant

    d0 = Ruote.define do
      35.times { noop }
      alpha
    end
    d1 = Ruote.define do
      3.times { noop }
      error 'oh crap'
    end

    #@engine.noisy = true

    i0 = @engine.launch(d0)
    i1 = @engine.launch(d1)

    r = @engine.wait_for(:alpha, :or_error)

    assert_equal i1, r['wfid']
    assert_equal 'error_intercepted', r['action']
  end
end

