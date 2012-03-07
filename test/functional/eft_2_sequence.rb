
#
# testing ruote
#
# Sat Jan 24 22:40:35 JST 2009
#

require File.expand_path('../base', __FILE__)


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

    #@dashboard.noisy = true

    assert_trace("a\nb", pdef)
  end

  def test_alice_bob_sequence

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        participant :ref => 'alice'
        participant :ref => 'bob'
      end
    end

    @dashboard.register_participant '.+' do |workitem|
      context.tracer << workitem.participant_name + "\n"
    end

    #noisy

    assert_trace("alice\nbob", pdef)
  end

  # Fri Dec 24 15:35:17 JST 2010
  #
  def test_let

    pdef = Ruote.process_definition do
      set 'v:var' => 'val'
      echo "out:${v:var}"
      let do
        set 'v:var' => 'val1'
        echo "in:${v:var}"
      end
      echo "out:${v:var}"
    end

    #noisy

    assert_trace %w[ out:val in:val1 out:val ], pdef
  end
end

