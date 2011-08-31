
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

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(2)
      # wait until the process reaches the 'lose' expression

    sleep 0.500

    ps = @engine.process(wfid)

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

    @engine.register_participant '.+' do |wi|
      @tracer << wi.participant_name
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(7)
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

    @engine.register_participant '.+', Ruote::StorageParticipant

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(6)
      # wait until 'alpha' replies to its parent 'lose'

    sleep 0.500

    assert_equal 1, @engine.storage_participant.size

    @engine.cancel_process(wfid)

    sleep 0.500

    assert_equal 0, @engine.storage_participant.size
    assert_nil @engine.process(wfid)
  end
end

