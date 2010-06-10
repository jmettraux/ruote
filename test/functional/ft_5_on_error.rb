
#
# testing ruote
#
# Tue Jun  2 18:48:02 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


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

    @marks = []

    @engine.register_participant 'mark\_.+' do |workitem|
      @marks << workitem.participant_name
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    assert_equal %w[ mark_started mark_failed mark_finished ], @marks
  end

  def test_on_error_unknown_participant_name_2

    pdef = Ruote.process_definition :name => 'test' do
      participant :mark_started
      participant :bogus, :on_error => :mark_failed
      participant :mark_finished
    end

    @marks = []

    @engine.register_participant 'mark\_.+' do |workitem|
      @marks << workitem.participant_name
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    assert_equal %w[ mark_started mark_failed mark_finished ], @marks
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

  def test_on_error_redo

    pdef = Ruote.process_definition do
      sequence :on_error => :redo do
        troublemaker
      end
    end

    hits = 0

    @engine.register_participant :troublemaker do
      hits += 1
      @tracer << "#{hits.to_s}\n"
      raise 'Houston, we have a problem !' if hits == 1
      @tracer << 'done.'
    end

    #noisy

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

  def test_on_error_undo__pass

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

    a_count = 0
    e_count = 0
    @engine.register_participant(:alpha) { |wi| a_count += 1 }
    @engine.register_participant(:emil) { |wi| e_count += 1 }

    #noisy

    assert_trace 'done.', pdef
    assert_equal 1, a_count
    assert_equal 1, e_count
  end

  def test_participant_on_error

    pdef = Ruote.process_definition do
      troublemaker :on_error => 'handle_error'
      define 'handle_error' do
        troublespotter
      end
    end

    workitem = nil

    @engine.register_participant :troublemaker do |wi|
      wi.fields['seen'] = true
      raise 'Beijing, we have a problem !'
    end
    @engine.register_participant :troublespotter do |wi|
      workitem = wi
      @tracer << 'err...'
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    #er = @engine.process(wfid).errors.first
    #puts er.message
    #puts er.trace

    assert_equal 'err...', @tracer.to_s
    assert_equal 4, workitem.error.size
    assert_equal 'RuntimeError', workitem.error[2]
    assert_equal true, workitem.fields['seen']
  end
end

