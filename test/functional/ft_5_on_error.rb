
#
# testing ruote
#
# Tue Jun  2 18:48:02 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/participant'


class FtOnErrorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_on_error

    pdef = Ruote.process_definition do
      sequence :on_error => 'catcher' do
        nada
      end
    end

    @engine.register_participant :catcher do
      @tracer << "caught\n"
    end

    #noisy

    assert_trace('caught', pdef)

    assert_equal 1, logger.log.select { |e| e['action'] == 'fail' }.size
  end

  def test_on_error_unknown_participant_name

    pdef = Ruote.process_definition :name => 'test' do
      participant :mark_started
      sequence :on_error => :mark_failed do
        participant :bogus
      end
      participant :mark_finished
    end

    @engine.context.stash[:marks] = []

    @engine.register_participant 'mark\_.+' do |workitem|
      stash[:marks] << workitem.participant_name
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    assert_equal(
      %w[ mark_started mark_failed mark_finished ],
      @engine.context.stash[:marks])
  end

  def test_on_error_unknown_participant_name_2

    pdef = Ruote.process_definition :name => 'test' do
      participant :mark_started
      participant :bogus, :on_error => :mark_failed
      participant :mark_finished
    end

    @engine.context.stash[:marks] = []

    @engine.register_participant 'mark\_.+' do |workitem|
      stash[:marks] << workitem.participant_name
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    assert_equal(
      %w[ mark_started mark_failed mark_finished ],
      @engine.context.stash[:marks])
  end

  def test_on_error_neutralization

    pdef = Ruote.process_definition do
      sequence :on_error => 'catcher' do
        sequence :on_error => '' do
          nada
        end
      end
    end

    @engine.register_participant :catcher do
      @tracer << "caught\n"
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)
    ps = @engine.process(wfid)

    assert_equal(1, ps.errors.size)
  end

  class TroubleMaker
    include Ruote::LocalParticipant
    def consume(workitem)
      hits = (workitem.fields['hits'] || 0) + 1
      workitem.fields['hits'] = hits
      workitem.trace << "#{hits.to_s}\n"
      raise 'Houston, we have a problem !' if hits == 1
      workitem.trace << 'done.'
      reply(workitem)
    end
    def cancel(fei, flavour)
      # nothing to do
    end
  end

  def test_on_error_redo

    pdef = Ruote.process_definition do
      sequence :on_error => :redo do
        troublemaker
      end
    end

    #noisy

    @engine.register_participant :troublemaker, TroubleMaker

    assert_trace(%w[ 1 2 done. ], pdef)
  end

  def test_on_error_retry

    pdef = Ruote.process_definition do
      sequence :on_error => :retry do
        troublemaker
      end
    end

    @engine.register_participant :troublemaker, TroubleMaker

    assert_trace(%w[ 1 2 done. ], pdef)
  end

  def test_on_error_undo

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        sequence :on_error => :undo do
          echo 'b'
          nemo
          echo 'c'
        end
        echo 'd'
      end
    end

    #noisy

    wfid = assert_trace(%w[ a b d ], pdef)

    assert_nil @engine.process(wfid)
  end

  def test_on_error_undo_single_expression

    @engine.register_participant :nemo do |wi|
      wi.fields['fail_count'] = 1
      raise 'nemo'
    end

    pdef = Ruote.process_definition do
      sequence do
        echo 'in'
        nemo :on_error => 'undo'
        echo '${f:error}|${f:fail_count}'
      end
    end

    wfid = assert_trace(%w[ in |1 ], pdef)

    assert_nil @engine.process(wfid)
  end

  def test_on_error_pass

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        sequence :on_error => :pass do
          echo 'b'
          nemo
          echo 'c'
        end
        echo 'd'
      end
    end

    #noisy

    wfid = assert_trace(%w[ a b d ], pdef)

    assert_nil @engine.process(wfid)
  end

  def test_missing_handler_triggers_regular_error

    pdef = Ruote.process_definition :on_error => 'failpath' do
      nemo
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)
    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size

    assert_equal 1, logger.log.select { |e| e['action'] == 'error_intercepted' }.size
  end

  def test_on_error_at_process_level

    pdef = Ruote.process_definition :on_error => 'failpath' do
      nemo
      define :failpath do
        echo 'failed.'
      end
    end

    #noisy

    assert_trace('failed.', pdef)
  end

  def test_with_concurrence

    pdef = Ruote.process_definition do
      sequence do
        concurrence :on_error => 'emil' do
          alpha
          error 'nada0'
          error 'nada1'
        end
        echo 'done.'
      end
    end

    @engine.context.stash[:a_count] = 0
    @engine.context.stash[:e_count] = 0

    @engine.register_participant(:alpha) { |wi| stash[:a_count] += 1 }
    @engine.register_participant(:emil) { |wi| stash[:e_count] += 1 }

    #noisy

    assert_trace 'done.', pdef
    assert_equal 1, @engine.context.stash[:a_count]
    assert_equal 1, @engine.context.stash[:e_count]
  end

  def test_participant_on_error

    pdef = Ruote.process_definition do
      troublemaker :on_error => 'handle_error'
      define 'handle_error' do
        troublespotter
      end
    end

    @engine.register_participant :troublemaker do |wi|
      wi.fields['seen'] = true
      raise 'Beijing, we have a problem !'
    end
    @engine.register_participant :troublespotter do |wi|
      stash[:workitem] = wi
      @tracer << 'err...'
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    #er = @engine.process(wfid).errors.first
    #puts er.message
    #puts er.trace

    wi = @engine.context.stash[:workitem]

    assert_equal 'err...', @tracer.to_s
    assert_equal 5, wi.error.size
    assert_equal 'RuntimeError', wi.error['class']
    assert_equal 'Beijing, we have a problem !', wi.error['message']
    assert_equal Array, wi.error['trace'].class
    assert_equal true, wi.fields['seen']
  end

  class Murphy
    include Ruote::LocalParticipant

    def cancel(fei, flavour)
      # nothing to do
    end
    def consume(workitem)
      raise "something got wrong"
    end
  end

  def test_subprocess_on_error

    pdef = Ruote.process_definition do
      sequence :on_error => 'error_path' do
        murphy
      end
      define 'error_path' do
        catcher
      end
    end

    @engine.register do
      murphy FtOnErrorTest::Murphy
      catchall
    end

    #@engine.noisy = true

    @engine.launch(pdef)

    @engine.wait_for(:catcher)
  end

  class RescuerOne
    include Ruote::LocalParticipant
    def consume(workitem)
      @context.tracer << 'one'
      reply_to_engine(workitem)
    end
    def accept?(workitem)
      false
    end
  end
  class RescuerTwo
    include Ruote::LocalParticipant
    def consume(workitem)
      @context.tracer << 'two'
      reply_to_engine(workitem)
    end
    #def accept?(workitem)
    #  true
    #end
  end

  def test_participants_and_accept

    pdef = Ruote.process_definition do
      sequence :on_error => 'rescuer' do
        nada
      end
    end

    @engine.register do
      rescuer RescuerOne
      rescuer RescuerTwo
    end

    #@engine.noisy = true

    assert_trace('two', pdef)

    assert_equal 1, logger.log.select { |e| e['action'] == 'fail' }.size
  end

  # Only to show what's behind :on_error
  #
  def test_on_error_multi

    pdef = Ruote.process_definition do
      sequence :on_error => [
        [ /unknown participant/, 'alpha' ],
        [ nil, 'bravo' ]
      ] do
        nada
      end
    end

    @engine.register_participant /alpha|bravo/ do |workitem|
      @tracer << workitem.participant_name
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)
    @engine.wait_for(wfid)

    assert_equal 'alpha', @tracer.to_s
  end

  def test_on_error_rewind

    pdef = Ruote.define do
      cursor :on_error => 'rewind' do
        echo 'in'
        inc 'v:counter'
        error 'fail', :if => '${v:counter} == 1'
        echo 'over.'
      end
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)
    @engine.wait_for(wfid)

    assert_equal %w[ in in over. ], @tracer.to_a
  end

  def test_on_error_jump_to

    pdef = Ruote.define do
      cursor :on_error => 'jump to shark' do
        alpha
        error 'fail'
        bravo
        shark
        delta
      end
    end

    #@engine.noisy = true

    @engine.register '.+' do |workitem|
      @tracer << workitem.participant_name + "\n"
    end

    wfid = @engine.launch(pdef)
    @engine.wait_for(wfid)

    assert_equal %w[ alpha shark delta ], @tracer.to_a
  end
end

