
#
# testing ruote
#
# Sat Jan 24 22:40:35 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class EftSequenceTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_sequence

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
      end
    end

    #noisy

    assert_trace('', pdef)
  end

  def test_a_b_sequence

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        echo 'a'
        echo 'b'
      end
    end

    #noisy

    assert_trace("a\nb", pdef)
  end

  def test_alice_bob_sequence

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        participant :ref => 'alice'
        participant :ref => 'bob'
      end
    end

    @engine.register_participant '.+' do |workitem|
      @tracer << workitem.participant_name + "\n"
    end

    #noisy

    assert_trace("alice\nbob", pdef)
  end
end

