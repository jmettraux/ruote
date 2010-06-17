
#
# testing ruote
#
# Tue Aug 11 13:56:28 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtBlockParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_workitems_dispatching_message

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'v0', :val => 'v0val'
        set :field => 'f0', :val => 'f0val'
        alpha
        bravo
        charly
      end
    end

    @engine.register_participant :alpha do
      @tracer << "a\n"
    end
    @engine.register_participant :bravo do |workitem|
      @tracer << "b:f0:#{workitem.fields['f0']}\n"
    end
    @engine.register_participant :charly do |workitem, fexp|
      @tracer << "c:f0:#{workitem.fields['f0']}:#{fexp.lookup_variable('v0')}\n"
    end

    #noisy

    assert_trace "a\nb:f0:f0val\nc:f0:f0val:v0val", pdef
  end

  TEST_BLOCK = Ruote.process_definition do
    sequence do
      alpha
      echo '${f:__result__}'
    end
  end

  def test_block_result

    return if Ruote::WIN or Ruote::JAVA
      # defective 'json' lib on windows render this test useless

    @engine.register_participant :alpha do |workitem|
      'seen'
    end

    #noisy

    assert_trace 'seen', TEST_BLOCK
  end

  def test_non_jsonfiable_result

    return if Ruote::WIN
      # defective 'json' lib on windows renders this test useless

    t = Time.now

    @engine.register_participant :alpha do |workitem|
      t
    end

    #noisy

    #assert_trace TEST_BLOCK, Ruote.time_to_utc_s(t)

    expected = if defined?(DataMapper)
      DataMapper::VERSION >= '1.0.0' ? t.to_s : ''
    elsif Ruote::JAVA
      ''
    else
      t.to_s
    end

    assert_trace expected, TEST_BLOCK
  end
end

