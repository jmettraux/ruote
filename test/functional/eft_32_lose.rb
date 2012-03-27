
#
# testing ruote
#
# Thu Nov 25 10:05:28 JST 2010
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class EftLoseTest < Test::Unit::TestCase
  include FunctionalBase

  def test_lose_alone

    pdef = Ruote.process_definition do
      lose
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(2)
      # wait until the process reaches the 'lose' expression

    sleep 0.500

    ps = @dashboard.process(wfid)

    assert_equal 0, ps.errors.size
    assert_equal 2, ps.expressions.size

    # the process is just stuck at the 'lose' expression
  end

  def test_losing_child

    pdef = Ruote.process_definition do
      lose do
        alpha
      end
      charly
    end

    @dashboard.register_participant '.+' do |wi|
      tracer << wi.participant_name
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(7)
      # wait until 'alpha' replies to its parent 'lose'

    sleep 0.500

    assert_equal 'alpha', @tracer.to_s
  end

  def test_cancelling_lose

    pdef = Ruote.process_definition do
      lose do
        alpha
      end
    end

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(6)
      # wait until 'alpha' replies to its parent 'lose'

    assert_equal 1, @dashboard.storage_participant.size

    @dashboard.cancel_process(wfid)

    @dashboard.wait_for(wfid)

    assert_equal 0, @dashboard.storage_participant.size
    assert_nil @dashboard.process(wfid)
  end

  def test_multi

    pdef = Ruote.define do
      lose do
        alpha
        bravo
      end
    end

    @dashboard.register '.+', Ruote::StorageParticipant

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(9)

    assert_equal 2, @dashboard.storage_participant.size
    assert_equal 0, @dashboard.ps(wfid).errors.size
    assert_equal 4, @dashboard.ps(wfid).expressions.size

    @dashboard.cancel(wfid)

    @dashboard.wait_for(wfid)

    assert_nil @dashboard.ps(wfid)
  end
end

