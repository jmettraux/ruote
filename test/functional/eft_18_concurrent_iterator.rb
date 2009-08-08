
#
# Testing Ruote (OpenWFEru)
#
# Wed Jul 29 23:25:44 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


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

  protected

  def register_catchall_participant

    @engine.register_participant '.*' do |workitem|
      @tracer << [
        workitem.participant_name, workitem.fei.sub_wfid, workitem.fei.expid
      ].join('/') + "\n"
    end
  end
end

