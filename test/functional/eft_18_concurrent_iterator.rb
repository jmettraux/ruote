
#
# Testing Ruote (OpenWFEru)
#
# Wed Jul 29 23:25:44 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

#require 'ruote/part/fs_participant'
require 'ruote/part/hash_participant'


class EftConcurrentIteratorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_iterator

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        concurrent_iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        end
        echo 'done.'
      end
    end

    #noisy

    assert_trace(pdef, 'done.')
  end

  def test_empty_list

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        concurrent_iterator :on_val => '', :to_var => 'v' do
          echo 'x'
        end
        echo 'done.'
      end
    end

    #noisy

    assert_trace(pdef, 'done.')
  end

  def test_iterator

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        participant '${v:v}'
      end
    end

    register_catchall_participant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    trace = @tracer.to_s.split("\n").sort
    assert_equal %w[ alice/0/0_0_0 bob/1/0_0_0 charly/2/0_0_0 ], trace
  end

  def test_iterator_to_f

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :on_val => 'alice, bob, charly', :to_field => 'f' do
        participant '${f:f}'
      end
    end

    register_catchall_participant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    trace = @tracer.to_s.split("\n").sort
    assert_equal %w[ alice/0/0_0_0 bob/1/0_0_0 charly/2/0_0_0 ], trace
  end

  def test_iterator_with_array_param

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        concurrent_iterator :on_val => %w[ a b c ], :to_field => 'f' do
          participant '${f:f}'
        end
        echo 'done.'
      end
    end

    register_catchall_participant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    trace = @tracer.to_s.split("\n").sort
    assert_equal %w[ a/0/0_0_0_0 b/1/0_0_0_0 c/2/0_0_0_0 done. ], trace
  end

  #def test_iterator_with_nested_sequence_and_fs_participants
  #  pdef = Ruote.process_definition :name => 'test' do
  #    sequence do
  #      concurrent_iterator :on_value => (1..10).to_a, :to_field => 'f' do
  #        sequence do
  #          participant_1
  #          participant_2
  #        end
  #      end
  #      participant_3
  #    end
  #  end
  #  p1 = @engine.register_participant :participant_1, Ruote::FsParticipant
  #  p2 = @engine.register_participant :participant_2, Ruote::FsParticipant
  #  p3 = @engine.register_participant :participant_3, Ruote::FsParticipant
  #  #noisy
  #  wfid = @engine.launch(pdef)
  #  sleep 0.500
  #  assert_equal [ 10, 0, 0 ], [ p1.size, p2.size, p3.size ]
  #  assert_not_nil @engine.process(wfid)
  #  while wi = p1.first; p1.reply(wi); end
  #  sleep 0.500
  #  assert_equal [ 0, 10, 0 ], [ p1.size, p2.size, p3.size ]
  #  assert_not_nil @engine.process(wfid)
  #  while wi = p2.first; p2.reply(wi); end
  #  sleep 0.500
  #  assert_equal [ 0, 0, 1 ], [ p1.size, p2.size, p3.size ]
  #  assert_not_nil @engine.process(wfid)
  #  p3.reply(p3.first)
  #  sleep 0.500
  #  assert_nil @engine.process(wfid)
  #end

  def test_iterator_with_nested_sequence_and_hash_participants

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        concurrent_iterator :on_value => (1..2).to_a, :to_field => 'f' do
          sequence do
            participant_1
            participant_2
          end
        end
        participant_3
      end
    end

    p1 = @engine.register_participant :participant_1, Ruote::HashParticipant
    p2 = @engine.register_participant :participant_2, Ruote::HashParticipant
    p3 = @engine.register_participant :participant_3, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:participant_1)

    assert_equal 0, p2.size
    assert_equal 0, p3.size

    p1.reply(p1.first)

    wait_for(:participant_2)

    assert_equal 1, p2.size
    assert_equal 0, p3.size

    p2.reply(p2.first)

    sleep 0.500

    assert_equal 0, p3.size
    assert_equal 1, p1.size
    assert_equal 0, p2.size
  end

  protected

  def register_catchall_participant

    @engine.register_participant '.*' do |workitem|
      @tracer << [
        workitem.participant_name, workitem.fei.sub_wfid, workitem.fei.expid
      ].join('/') + "\n"
    end
  end
end

