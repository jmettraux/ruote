
#
# testing ruote
#
# Thu Nov 25 11:20:04 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

#require 'ruote/part/storage_participant'


class FtLoseTest < Test::Unit::TestCase
  include FunctionalBase

  def test_lose_participiant

    pdef = Ruote.process_definition do
      sequence do
        alpha :lose => true
        alpha
      end
    end

    @engine.register_participant '.+' do |wi|
      @tracer << wi.participant_name + "\n"
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(6)

    #sleep 0.500

    assert_equal 'alpha', @tracer.to_s

    ps = @engine.process(wfid)

    assert_equal 3, ps.expressions.size
    assert_equal 0, ps.errors.size
      # the sequence is stuck, the lost alpha is not replying
  end

  def test_lose_sequence

    pdef = Ruote.process_definition do
      concurrence do
        alpha
        sequence :lose => 'true' do
          bravo
        end
      end
    end

    @engine.register_participant '.+' do |wi|
      @tracer << wi.participant_name + "\n"
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(12)

    assert_match /alpha/, @tracer.to_s
    assert_match /bravo/, @tracer.to_s

    ps = @engine.process(wfid)

    assert_equal 3, ps.expressions.size
    assert_equal 0, ps.errors.size
      # the concurrence is stuck, the lost sequence won't reply
  end

  def test_cancel_lost_expression

    pdef = Ruote.define do
      sequence do
        alpha
        bravo :lose => true
        charly
      end
    end

    @engine.register_participant '.+' do |wi|
      @tracer << wi.participant_name + "\n"
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(12)
      # until bravo is reached

    #sleep 0.500

    assert_equal "alpha\nbravo", @tracer.to_s

    bravo = @engine.process(wfid).expressions.last

    @engine.cancel_expression(bravo.fei)

    @engine.wait_for(wfid)

    assert_equal "alpha\nbravo\ncharly", @tracer.to_s
    assert_nil @engine.process(wfid)
  end
end

